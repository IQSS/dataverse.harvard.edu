#!/bin/bash -x

#MAC
#startDate="$(date -v-7d +%Y-%m-%d)"
#Linux
startDate="$(date -d "-7 days" +%Y-%m-%d)"
today=$(date +%Y-%m-%d)
echo "$startDate  -  $today"
TOKEN=$(sed -n 's/^hub_api_token:[[:space:]]*//p' /usr/local/counter-processor-1.06/config/secrets.yaml)
REPOSITORY_ID="gdcc.harvard-dv"

declare -i page=1

processDataCite() {
  rm /tmp/counter_weekly.lst
  processDataCitePage "1"
}
processDataCitePage() {
  #local query="updated:\[$startDate%20TO%20$today\]%20AND%20relatedIdentifiers.relationType:(IsCitedBy%20OR%20IsReferencedBy%20OR%20IsSupplementedBy)&page\[size\]=1000&page\[cursor\]=$1&fields\[dois\]=id&client-id=$REPOSITORY_ID"
  local query="updated:\[$startDate%20TO%20$today\]&page\[size\]=1000&page\[cursor\]=$1&fields\[dois\]=id&client-id=$REPOSITORY_ID"
  local URL="https://api.datacite.org/dois?query=${query}"
  local jsonData=$(curl -H "Authorization: Bearer $TOKEN" "$URL") 2>/dev/null
  echo "$jsonData" > /tmp/counter_weekly.json
  for row in $(jq -r '.data[] | @base64' /tmp/counter_weekly.json); do
      _jq() {
         echo "${row}" | base64 --decode | jq -r "${1}"
      }
      DOI=$(_jq '.id')
      echo "$DOI" >> /tmp/counter_weekly.lst
  done
  page=$((page + 1))
  next=$(echo "$jsonData" | jq -r '.links.next')
  declare -i totalPages=$(echo "$jsonData" | jq -r '.meta.totalPages')
  if [[ -n "$next" && "$page" -le "$totalPages" ]]; then
    processDataCitePage "$next"
  fi
}

processDataverse() {
  local DOI=""
  while IFS= read -r line; do
      DOI=${line}
      HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "http://localhost:8080/api/admin/makeDataCount/:persistentId/updateCitationsForDataset?persistentId=doi:$DOI")
  done < "/tmp/counter_weekly.lst"

  # Extract the HTTP status code from the last line
  HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n1)
  # Extract the response body (everything except the last line)
  RESPONSE_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')

  # Check the HTTP status code and report accordingly
  case $HTTP_STATUS in
      200)
          # Successfully queued
          # Extract status from the nested data object
          STATUS=$(echo "$RESPONSE_BODY" | jq -r '.data.status')

          # Extract message from the nested data object
          if echo "$RESPONSE_BODY" | jq -e '.data.message' > /dev/null 2>&1 && [ "$(echo "$RESPONSE_BODY" | jq -r '.data.message')" != "null" ]; then
              MESSAGE=$(echo "$RESPONSE_BODY" | jq -r '.data.message')
              echo "[SUCCESS] doi:$DOI - $STATUS: $MESSAGE"
          else
              # If message is missing or null, just show the status
              echo "[SUCCESS] doi:$DOI - $STATUS: Citation update queued"
          fi
          ;;
      400)
          # Bad request
          if echo "$RESPONSE_BODY" | jq -e '.message' > /dev/null 2>&1; then
              ERROR=$(echo "$RESPONSE_BODY" | jq -r '.message')
              echo "[ERROR 400] doi:$DOI - Bad request: $ERROR"
          else
              echo "[ERROR 400] doi:$DOI - Bad request"
          fi
          ;;
      404)
          # Not found
          if echo "$RESPONSE_BODY" | jq -e '.message' > /dev/null 2>&1; then
              ERROR=$(echo "$RESPONSE_BODY" | jq -r '.message')
              echo "[ERROR 404] doi:$DOI - Not found: $ERROR"
          else
              echo "[ERROR 404] doi:$DOI - Not found"
          fi
          ;;
      503)
          # Service unavailable (queue full)
          if echo "$RESPONSE_BODY" | jq -e '.message' > /dev/null 2>&1; then
              ERROR=$(echo "$RESPONSE_BODY" | jq -r '.message')
              echo "[ERROR 503] doi:$DOI - Service unavailable: $ERROR"
          elif echo "$RESPONSE_BODY" | jq -e '.data.message' > /dev/null 2>&1; then
              ERROR=$(echo "$RESPONSE_BODY" | jq -r '.data.message')
              echo "[ERROR 503] doi:$DOI - Service unavailable: $ERROR"
          else
              echo "[ERROR 503] doi:$DOI - Service unavailable: Queue is full"
          fi
          ;;
      *)
          # Other error
          echo "[ERROR $HTTP_STATUS] doi:$DOI - Unexpected error"
          echo "Response: $RESPONSE_BODY"
          ;;
  esac
}

processDataCite
processDataverse
