Large Data Storage and Globus Support at Harvard Dataverse
==========================================================

Below are the end-user instructions on how to use Globus for transferring data to and from large data storage volumes at NESE.

The simplified [Quick Start](download-quickstart.md) download guide documents the bare minimum required for a Harvard Dataverse user to start downloading Globus-accessible data. 

The following 2 guides, on how to [download](download.md) and [upload](upload.md) data are more detailed with some information on more complex use cases, troubleshooting and more. If you are a data depositor, it is strongly recommended that you review the _download_ instructions as well, to get a clear idea of what the process of accessing your data will be like for the end users.

Please keep in mind the experimental, and work-in-progress nature, both of these documents and the Globus support in Dataverse overall.

# FAQ:

## What is Globus anyway?

[Globus](https://www.globus.org/data-transfer) is a transfer protocol optimized for large data volumes. It offers features that make TB-sized uploads and downloads practical. The most important of which is that it handles interruptions and restarts automatically in the background, without needing any intervention from the user. As a tradeoff, it makes the upload and download workflow more complex, compared to the methods traditionally offered in Dataverse, via the web interface or the API. At a minimum, it requires an extra application component to be installed locally, and generally involves more steps than, for ex., simply clicking on the upload link in the browser and picking a file on your drive.

## Why do we need to use Globus again?

This new and experimental Large Data Storage service gives Harvard Dataverse users access to the Big Data storage infrastructure at [Northeast Storage Exchange](https://nese.mghpcc.org/) (NESE), which is accessible via Globus only.

## Can I use the existing Dataverse Data Access API to upload and download NESE-stored data?

No, at the moment, there is no API access offered to the data stored at NESE that is easily scriptable or usable on the command line. There's no S3, or any direct HTTP access to the files either. Therefore the only currently supported way to upload or download NESE data is the process described in these guides here, where all the transfers must be initiated in the web user interface.

A command line upload and/or download client may be developed at a later date. 