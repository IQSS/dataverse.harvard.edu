#!/bin/sh
for i in `ls metadatablocks/*.tsv`; do
    echo "Loading metadata block: $i"
    curl http://localhost:8080/api/admin/datasetfield/load -X POST --upload-file $i -H "Content-type: text/tab-separated-values"
done
