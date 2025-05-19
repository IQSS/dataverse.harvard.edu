#! /bin/bash
set -x

# This script will process each file from s3 bucket where archive log files are stored
# 1. Loop through each file not already processed (by date).
# 2. Call counter-processor to convert the log files to SUSHI formatted files
# 3. counter-processor will call Dataverse API: /api/admin/makeDataCount/addUsageMetricsFromSushiReport?reportOnDisk=... to store dataset metrics in dataverse DB.
# 4. counter-processor will upload the data to DataCite if upload_to_hub is set to True.
# 5. The state of each file is inserted in Dataverse DB. This allows failed files to be re-tried as well as limiting the number of files being processed with each run.

# MDC logs. There is one log per node per day, .../domain1/logs/counter_YYYY-MM-DD.log
# To enable MDC logging set the following settings:
# curl -X PUT -d 'false' http://localhost:8080/api/admin/settings/:DisplayMDCMetrics
# curl -X PUT -d '/opt/dvn/app/payara6/glassfish/domains/domain1/logs' http://localhost:8080/api/admin/settings/:MDCLogPath
# Processing States:
# NEW("new"), DONE("done"), SKIP("skip"), PROCESSING("processing"), FAILED("failed");
# To run this script:
#   sudo nohup /usr/local/bin/process_mdc_logs.sh  >> /tmp/process_mdc_logs.log 2>&1 &
# crontab: sudo crontab -l -u root
# sudo crontab -u root 0 * * * * /usr/local/bin/process_mdc_logs.sh >> /tmp/process_mdc_logs.log 2>&1

# Used to rotate the log file. Must match the log file name in the crontab
LOGFILE=/tmp/process_mdc_logs.log

declare -a NODE=("app-1" "app-2")
# change SERVER if running this script on multiple servers. It doesn't need to match the NODE. It just needs to be unique.
SERVER=app-1
COUNTERPROCESSORDIR=/usr/local/counter-processor-1.06
TMPDIR=/uploads/mdc_proc
TMPLOGDIR=$TMPDIR/log
# Report directory shared by counter and dataverse
RPTDIR=/tmp
ARCHIVEDIR=s3://dvn-cloud/Admin/logs/payara/counter
ListFromArchiveCmd="aws s3 ls ${ARCHIVEDIR}"
CopyFromArchiveCmd="aws s3 cp ${ARCHIVEDIR}"
# Must set up:  sudo visudo  and add '%iqss   ALL=(ALL)       NOPASSWD: ALL'
RunAsCounterProcessorUser="sudo -u counter"
RunCounterProcessorCommand="python3.11 -u main.py"
output_report_file=tmp/make-data-count-report
upload_to_hub=False
clean_for_rerun=False
platform_name="Harvard Dataverse"
hub_base_url="https://api.datacite.org"
cache_size=-64000
# If uploading to DataCite make sure the hub_api_token is defined in COUNTERPROCESSORDIR/config/secrets.yaml and not hard coded in this script

# Testing with dataverse running in docker
if [ -d docker-dev-volumes/ ]; then
  echo "Docker Directory exists."
  RunAsCounterProcessorUser="sudo"
  DATAVERSESOURCEDIR=$PWD
  COUNTERPROCESSORDIR=$DATAVERSESOURCEDIR/../counter-processor
  TMPDIR=$DATAVERSESOURCEDIR/docker-dev-volumes/app/data/temp
  TMPLOGDIR=$TMPDIR/log
  RPTDIR=$TMPDIR
  ARCHIVEDIR=$DATAVERSESOURCEDIR/tests/data
  ListFromArchiveCmd="ls ${ARCHIVEDIR}"
  CopyFromArchiveCmd="cp -v ${ARCHIVEDIR}"
  platform_name="Harvard Dataverse Test Account"
  hub_base_url="https://api.test.datacite.org"
  upload_to_hub=False
fi

log_name_pattern="$TMPLOGDIR/counter_(yyyy-mm-dd).log"

# This config file contains the settings that can not be overwritten here.
# path_types:
#    investigations:
#    requests:
#export CONFIG_FILE="${COUNTERPROCESSORDIR}/config/counter-processor-config.yaml"
export CONFIG_FILE="${COUNTERPROCESSORDIR}/config/config.yaml"
# See: https://guides.dataverse.org/en/latest/admin/make-data-count.html#configure-counter-processor
# and download https://guides.dataverse.org/en/latest/_downloads/f99910a3cc45e4f68cc047f7c033c7f0/counter-processor-config.yaml

function process_json_file () {
  # Process the logs by calling counter-processor
  year_month="${1}"
  cd $TMPLOGDIR
  l=$(ls counter_${year_month}-*.log | sort -r)
  log_date=${l:8:10}
  sim_date=$(date +%Y-%m-%d -d "${log_date}+1 days")
  response=$(curl -sS -X GET "http://localhost:8080/api/admin/makeDataCount/$year_month/processingState") 2>/dev/null
  state=$(echo "$response" | jq -j '.data.state')

  curl -sS -X POST "http://localhost:8080/api/admin/makeDataCount/$year_month/processingState?state=processing&server=$SERVER"
  echo "${year_month}" > ${TMPDIR}/process_mdc_logs.txt

  cd $COUNTERPROCESSORDIR
  eval "$RunAsCounterProcessorUser YEAR_MONTH=${year_month} SIMULATE_DATE=${sim_date} PLATFORM='${platform_name}' LOG_NAME_PATTERN='${log_name_pattern}' OUTPUT_FILE='${output_report_file}' UPLOAD_TO_HUB='${upload_to_hub}' HUB_BASE_URL='${hub_base_url}' CLEAN_FOR_RERUN='${clean_for_rerun}' PRAGMA_CACHE_SIZE=${cache_size} ${RunCounterProcessorCommand}"
  if [ $? -ne 0 ]; then
      state="failed"
  else
      # display the response from upload to datacite if it exists (upload_to_hub=true)
      if [[ -f "${tmp/datacite_response_body.txt}" ]]; then
          cat ${tmp/datacite_response_body.txt}
      fi

      # handle batches ${output_report_file}.json.{batch}
      i=0
      reports_on_disk=()
      for file in "$output_report_file".json.*; do
          report_on_disk=${RPTDIR}/counter_${year_month}.json.${i}
          cp -v ${file} ${report_on_disk}
          i=$((i+1))
          reports_on_disk[$i]=${report_on_disk}
      done
      printf "%s\n" "${reports_on_disk[@]}"

      for i in "${!reports_on_disk[@]}"; do
          report_on_disk=${reports_on_disk[$i]}
          response=$(curl -sS -X POST "http://localhost:8080/api/admin/makeDataCount/addUsageMetricsFromSushiReport?reportOnDisk=${report_on_disk}") 2>/dev/null
          echo $response
          if [[ "$(echo "$response" | jq -j '.status')" != "OK" ]]; then
            state="failed"
            break
          else
            state="done"
            rm -rf ${report_on_disk}
          fi
      done
      if [[ "${state}" == "done" ]] ; then
        rm ${TMPDIR}/process_mdc_logs.txt
      fi
  fi
  curl -sS -X POST "http://localhost:8080/api/admin/makeDataCount/$year_month/processingState?state="$state
}

function process_archived_files () {
  eval "mkdir -p ${TMPLOGDIR}"
  eval "chmod -R a+rwx ${TMPLOGDIR}"
  # Check if we need to continue processing the same year_month
  continue_year_month=""
  if [ -f "${TMPDIR}/process_mdc_logs.txt" ]; then
    continue_year_month=$(head -n 1 ${TMPDIR}/process_mdc_logs.txt)
  fi
  echo $continue_year_month
  # Check each node for the newest file. If multiple nodes have the same date file we need to merge the files
  nodeArraylength=${#NODE[@]}
  for (( i=0; i<${nodeArraylength}; i++ ));
  do
    echo "index: $i, value: ${NODE[$i]}"
    for l in $($ListFromArchiveCmd/${NODE[$i]}/ | rev | cut -d' ' -f1 | rev | sort -r) ; do
        year_month=${l:(-11):7}
        echo "Found archive file for "$year_month
        response=$(curl -sS -X GET "http://localhost:8080/api/admin/makeDataCount/$year_month/processingState") 2>/dev/null
        state=$(echo "$response" | jq -j '.data.state')
        stateServer=$(echo "$response" | jq -j '.data.server')
        if [[ "${state}" == "DONE" ]] || [[ "${state}" == "SKIP" ]]; then
          echo "Skipping due to state:${state}"
        elif [[ "${stateServer}" != "null" ]] && [[ "${stateServer}" != $SERVER ]]; then
          echo "Skipping due to server:${stateServer}"
        elif [[ -n "${continue_year_month}" ]] && [[ "${continue_year_month}" != $year_month ]]; then
          echo "Skipping due to not the year month that was being processed: $year_month != ${continue_year_month}"
        else
          NODE_LOGDIR=${TMPLOGDIR}/${NODE[$i]}_${year_month}
          eval "mkdir -p ${NODE_LOGDIR}"
          # Copy the tar file from archive back to local, un-tar it and clean up intermediate files.
          eval "$CopyFromArchiveCmd/${NODE[$i]}/counter_${year_month}.tar ${NODE_LOGDIR}"
          tar -xvf ${NODE_LOGDIR}/counter_${year_month}.tar --directory ${NODE_LOGDIR}
          ls ${NODE_LOGDIR}/counter_${year_month}-* | while read l
          do
            gzip -d $l
          done
          rm -r ${NODE_LOGDIR}/counter_${year_month}.tar
          break
        fi
    done
  done

  # Determine which node/nodes have the newest files. Unless a node was down for the month they should all have files
  # for the same dates so merging is a must.
  # Get a list of directories under NODE_LOGDIR that are in format NODE_yyyy-mm and strip to get yyyy_mm
  # Sort so newest yyyy-mm is first in the list
  ls -1d $TMPLOGDIR/* | rev | cut -d'_' -f1 | rev | sort -r | uniq > $TMPDIR/archived_files
  # Read first line and strip off trailing '/' to get the newest year_month to process
  read -r line < $TMPDIR/archived_files
  year_month=${line:(0):7}
  echo $year_month
  # year_month will be empty if no more files to process
  if [ ! -z "$year_month" ]; then
    # Get the list of directories to merge for this year_month
    ls -1d $TMPLOGDIR/*_$year_month/ > $TMPDIR/archived_files

    # Merge subsequent directories into firstDirectory. Note: firstDirectory may or may not be NODE 1. It shouldn't matter
    read -r firstDirectory < $TMPDIR/archived_files
    tail -n +2 $TMPDIR/archived_files| while read l
    do
       ls ${l}counter_*.log | while read l
         do
           # It should never happen but if 1 of the files is missing create it so the merge will not fail
           if [ ! -e "$l" ]; then
             touch $l
           fi
           # Strip off just the file name ie. counter_2024-02-01.log
           log_file=${l:(-22)}
           sort -um -o ${firstDirectory}${log_file} ${firstDirectory}${log_file} ${l}
        done
    done < $TMPDIR/archived_files

    # Now firstDirectory has all the merged data so we can move it to the counter_processor log directory and clean up the NODE directories
    eval "cp ${firstDirectory}*.log $TMPLOGDIR"
    for (( i=0; i<${nodeArraylength}; i++ ));
    do
      rm -rf $TMPLOGDIR/${NODE[$i]}*
    done

    process_json_file "$year_month"

    # After processing is done delete the log files from the log directory
    eval "rm -rf ${TMPLOGDIR}/counter_*.log"
    # Rotate the log file
    if [ -f "$LOGFILE" ]; then
        eval "mv -f $LOGFILE $LOGFILE.$year_month"
    fi
  fi
}

# Main
# see if this is already running
if eval "ps aux | grep -v 'grep' | grep '${RunCounterProcessorCommand}'"; then
  echo "Process is already running. Exiting!"
elif eval "ps aux | grep -v 'grep' | grep 'makeDataCount/addUsageMetricsFromSushiReport'"; then
  echo "Uploading to Dataverse is already running. Exiting!"
else
  process_archived_files
fi
