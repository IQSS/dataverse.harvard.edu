#!/bin/sh
echo "Setting up Data Curation Tool"
TOOL=$(curl http://localhost:8080/api/admin/externalTools | grep "Data Curation Tool")
if [ -z "${TOOL}" ]; then
    response=$(curl -X POST -H 'Content-type: application/json'  http://localhost:8080/api/admin/externalTools --upload-file dataverse-manifest.json 2>&1)
    if [ $? -ne 0 ] ; then
       echo "Error: ""$response" && exit;
    fi
fi

docker compose up -d &

