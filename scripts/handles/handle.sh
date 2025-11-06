#! /bin/bash
#set -x

HANDLEDIR=/handle-9.3.2/bin
PASSPHRASE=
PREFIX=1902.1
#PREFIX=10904
ADMINHANDLE=0.NA/$PREFIX
LISTFILE=list-$PREFIX.txt
BATCHFILE=batch-$PREFIX.txt
FAILURES=failures-$PREFIX.txt

ID=X
URL=X

function verify-url () {
  echo "CURL" $URL
  http_status=$(curl -s -o /dev/null --write-out "%{http_code}" ${URL//[\'\"]/})
  echo "HTTP Status Code:" $http_status
  if [ "$http_status" -eq 301 ] || [ "$http_status" -eq 302 ] || [ "$http_status" -eq 200 ]; then
    echo "Request successful."
  else
    echo "$http_status $ID $URL " >> $FAILURES
  fi
}

# STEP 1
function get-list () {
  eval "$HANDLEDIR/hdl-list -s $ADMINHANDLE 300 $HANDLEDIR/admpriv.bin $PREFIX > $LISTFILE" <<< $PASSPHRASE
}

#STEP 2
function verify-list () {
  rm -f  $FAILURES
  echo "AUTHENTICATE PUBKEY:300:$ADMINHANDLE" > $BATCHFILE
  echo "$HANDLEDIR/admpriv.bin|$PASSPHRASE" >> $BATCHFILE
  while IFS= read -r line; do
    # Process each line here
    if [[ "$line" == "$PREFIX"* ]]; then
      ID=$line
    elif [[ -n "$line" && "$line" =~ "type=URL" ]]; then
      echo "LINE" $line
      words=( $line )
      URL=${words[3]}
      URL=$(echo "$URL" | tr -d '"')
      echo "ID and URL"  $ID $URL
      verify-url
      echo "" >> $BATCHFILE
      echo "MODIFY $ID" >> $BATCHFILE
      if [[ "$URL" == *"dataset.xhtml"* ]]; then
        URL={$URL/dataset.xhtml/citation}
      fi
      # Index 1 (url)  Type 'URL'  TTL 86400 = 24 hours  Permission set (admin read, admin write, public read, public write) (1110)
      echo "1 URL 86400 1110 UTF8 $URL" >> $BATCHFILE
    fi
  done < $LISTFILE
}

#STEP 3
function batch-update () {
  rm -f  $BATCHFILE.log
  eval "$HANDLEDIR/hdl-genericbatch $BATCHFILE $BATCHFILE.log"
}

#Main
# Get a list of handles. Skip if list file exists
if [ -e "$LISTFILE" ]; then
  echo "$LISTFILE exists. Skipping this step"
else
  echo "$LISTFILE does not exist."
  get-list
fi

# Verify the list of URLs and build a batch file. Skip if failure file exists
if [ -e "$FAILURES" ]; then
  echo "$FAILURES exists. Skipping this step"
else
  echo "$FAILURES does not exist."
  verify-list
fi

# Modify urls that need changing via batch file. Skip if batch file does not exist
if [ -e "$BATCHFILE" ]; then
  echo "$BATCHFILE exists."
  batch-update
else
  echo "$BATCHFILE does not exist. Skipping this step"
fi
