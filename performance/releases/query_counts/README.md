## Query counts on the "workhorse" jsf pages, as part of a proposed release performance test checklist

These proposed tests serve to further help prevent an unacceptable performance degradataion in the 2 "workhorse" jsf pages, dataverse.xhtml and dataset.xhtml.

Queries are counted for the following 2 pages:

dataverse page: http://localhost:8080/dataverse/harvard (home page)
dataset page: http://localhost:8080/dataset.xhtml?persistentId=doi:10.7910/DVN/29236 (this is the dataset with the most files - ~1,500 out of the 10 "control datasets" used in the performance tests).

The results should be checked in here. For example, when testing for the 6.8-RC the following results have been saved:

```
6.8-RC/queries_dataset_29236-6.7.1.txt
6.8-RC/queries_dataset_29236-6.8-RC.txt
6.8-RC/queries_homepage-6.7.1.txt
6.8-RC/queries_homepage-6.8-RC.txt
```

(the query counts in the results above turned out to be identical between 6.7.1 and 6.8-RC - ~700 for the dataverse and ~2,000 for the dataset pages above)

