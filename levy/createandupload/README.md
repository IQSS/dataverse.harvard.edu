Code added to check on the status of the API calls that create the dataset and upload the image file.

The goal is to make sure we don't attempt to send any further requests while the last request is still being processed. This mostly concerns the reindexing of the dataset that happens in the background after both the initial create, and the upload calls. I.e., even after the call to the upload API returns "OK", that indexing may still be happening in the background. So we use the `/datasets/:persistentId/timestamps?persistentId={1}` API to check on the timestamps associated with the Datasets. If either `hasStaleIndex` or `hasStalePermissionIndex` fields in the output is `True`, that means the dataset is still being indexed, so we sleep for 10 sec., then try again, etc. until it's done. (While it shouldn't be necessary to be this careful when creating small numbers of datasets, this can potentially become a problem when this process is repeated hundreds+ times, if these calls start stacking up).

All the added code in example.ipynb is in under "create dataset and add file" (cell 9). All the other cells in this example are the same as in the original Levy notebook.

The most important code is the following block where we check on the indexing status:

```
# check if indexing is still chugging along:
timestamp_url = \"{0}/datasets/:persistentId/timestamps?persistentId={1}\".format(api.base_url_api_native,pid)
has_stale_index=True
has_stale_perm_index=True
while has_stale_index or has_stale_perm_index:
    print('sleeping...')
    sleep(10)
    # make the API call; if these index stamps are still \"stale\", we'll sleep some more, check again, (repeat)
    resp_timestamps=api.get_request(timestamp_url, True)
    if 'data' in resp_timestamps.json().keys():
        has_stale_index=resp_timestamps.json()['data']['hasStaleIndex']
        has_stale_perm_index=resp_timestamps.json()['data']['hasStalePermissionIndex']
    else:
        print('failed to get a response from /timestamps api; will sleep and try again.')
# OK, the dataset is ready and has been reindexed successfully. Safe to proceed.
```

(the above block can be easily reused whenever you modify a dataset and want to ensure that Dataverse is done indexing it).


