The python code in the file example.py in this directory is for the notebook cell where the draft datasets get published.

The publishing process is particularly tricky - the API always returns `OK` right away and the all the (potentially long-running tasks, such as the Datacite registration, etc.) are performed in the background. The dataset is locked for the duration of this process, with a lock of type `finalizePublication`. This lock prevents the user from attempting to do any edits/modifications on the dataset... but it's not going to prevent them from proceeding to publish another dataset. So in a situtation where we are publishing a large number of different datasets, it would be possible to fire too many requests in parallel. So this code makes sure to only proceed with publishing the next dataset once the last one is finished. Instead of sleeping for a fixed number of seconds, it uses the `/datasets/{id}/locks` API to check if the lock is still there; if the dataset is still locked, it sleeps for 10 seconds, then tries again, etc.

If the initial publish API request does not return an `OK` response, we skip the dataset and proceed to the next one. Only the successful responses are added to the `published_dois` array. 
