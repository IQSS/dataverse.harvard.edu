## A full reindex of the prod. database clone as part of the "performance tests" release step.

I'm proposing to perform a full, from-scratch reindex of the prod. db clone, as part of the overall performance test of a release candidate.

The steps involved:
- Deploy the release candidate on qa.dataverse.org;
- Erase the index on the perf. solr service; make sure Dataverse is showing an empty collection;
- Run a reindex; make sure it completes;
- Record the result here, in RESULTS_full_reindex.tsv, commit the result.

The purpose is to a) Detect if some unacceptable inefficiency has been introduced in a release (if reindex-all now takes 2X, I would consider it a cause for alarm) b) Have an idea of how long a reindex will take in real prod., if needed. The rule of thumb is that the time a reindex takes in prod. is roughly 50% of what it takes on the perf. system. Also, c) It is objectively useful to rebuild the QA index from scratch once every few months, since our database-syncing routine otherwise results in some number of stale solr index entries pointing to datasets etc. that are no longer in the database.

Unless the indexing speed was explicitlty optimized in the release being tested, the reindex will inevitably take longer than it did 3 months ago, due to the database growth. Case in point: it took 24 hrs in 6.7-RC, and it has taken 27.5 hrs in 6.8-RC. In the 3 month period between the 2 runs the number of datasets has increased by 22,000 (10%) and the number of files by 309,000 (6%) respectively. It is impossible to easily tell if all of the increase above can be accounted for by the sheer volume growth vs. (potentially) by any new inefficiencies. But the magnitude of the increase should be considered acceptable. (there may be questions about the long-term sustainability of such growth, but that's outside of the scope here).

But, since we know for the fact that indexing is particularly expensive for datasets with large numbers of files, I propose that we record the current list of the datasets vs. file numbers here, as an extra data point. Use the query provided here (`order_datasets_for_indexing.sql`) and check in the result (for ex., `datasets_ordered_by_filesnumber-6.8-RC.txt`). Note that this is the same database query that Dataverse uses internally to determine the indexing order (we index empty, cheaper-to-index datasets first). 
