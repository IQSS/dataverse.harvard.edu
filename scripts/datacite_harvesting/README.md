# Clients configuration for harvesting from DataCite via OAI-PMH

This directory contains the scripts that can be used to create harvesting client configurations for harvesting from DataCite via OAI-PMH, the json fragments that can then be fed to `/api/harvest/clients/...`.

Note that the support for harvesting from DataCite is still new and experimental; as of writing this (01/03/2024) the code is not yet in a released version of Datavers and is being used in our production via a custom patch.

Harvesting datasets from Bertarelli Foundation is used to illustrate the process (this is our first real time use case of the feature). There is a relatively small number of individual dois (28 total) to harvest, but the hierarchy is somewhat complex - the datasets are harvested into 9 different subcollections total (therefore 9 individual clients are created). We harvest the datasets by their individual dois, but virtually any search query that the DataCite api can understand can be turned into a "set" that can be harvested from their OAI-PMH server.

The list of the individual dois mapped to the destination collections is supplied in `bertarelli-dois-subcollections.txt`. The list of 9 unique subcollections is supplied in `bertarelli_subcollections.txt`. 

## Step 1.: create encoded "sets" from the lists of dois for each collection:

```shell
cat bertarelli_subcollections.txt | while read alias  
do
    echo -n "$alias "

    grep "$alias" bertarelli-dois-subcollections.txt | awk '{print $1}' | ./script_encode.pl | base64
done > subcollections_and_sets.txt
```

## Step 2.: then cook the harvesting client configurations: 

```shell
mkdir clients
cat subcollections_and_sets.txt | ./script_cookclients.pl
```

The step above will produce individual harvesting configurations for each subcollection along the lines of

```javascript
{
    "useOaiIdentifiersAsPids": true,
    "useListRecords": true,
    "allowHarvestingMissingCVV": false,
    "set": "~ZG9pJTNBKDEwLjUyODEvWkVOT0RPLjYzODExMzAlMjBPUiUyMDEwLjUyODEvWkVOT0RPLjc4MDU5MzUpCg==",
    "nickName": "bertarelli",
    "dataverseAlias": "bertarelli",
    "type": "oai",
    "style": "default",
    "harvestUrl": "https://oai.datacite.org/oai",
    "archiveUrl": "https://oai.datacite.org",
    "archiveDescription": "The metadata for the Dataset was harvested from DataCite. Clicking the dataset link will take you directly to the original archival location, as registered with DataCite.",
    "metadataFormat": "oai_dc"
  }
```

## Step 3.: then the harvesting clients can be created as follows:

```shell
cat bertarelli_subcollections.txt  | 
while read alias
do 
   curl  -H "X-Dataverse-key: [redacted]" -X POST -H "Content-Type: application/json" "http://localhost:8080/api/harvest/clients/${alias}" --upload-file clients/${alias}.json
   echo
   echo $alias
   sleep 4
done
```



