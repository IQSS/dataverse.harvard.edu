# Data Curation Tool

An external tool for exploring and curating Dataverse tab delimited DataFiles
The tool source can be found in this GitHub repositiry:
https://github.com/scholarsportal/Dataverse-Data-Explorer/blob/main/README.md

## Installing the tool in Apache:

This is used for installing in demo and production.

Build the source per the instructions in the README of the Dataverse-Data-Explorer project linked above. Use ng build to create the dist folder.

- ng build

(Note: If the dist/index.html file has 'base href="/"' change it to base href="./" )

zip the dist/ directory and copy it to the Dataverse server
On the Dataverse server unzip the file and rename dist/ to datacuration/
- unzip dist.zip
- mv dist/ datacuration/
- sudo cp -r datacuration/ /var/www/html/
- sudo vi /etc/httpd/conf.d/ssl.conf
  
  Add to ssl.conf 'ProxyPassMatch ^/datacuration !' to the '# don't pass paths used by rApache...' section.
- sudo apachectl graceful

Load the setting to configure Dataverse to use the external tool:

Copy the appropriate json file to the server

    dataverse-manifest-demo.json or dataverse-manifest-prod.json and rename it to local-dataverse-manifest.json
curl -X POST -H 'Content-type: application/json' http://localhost:8080/api/admin/externalTools --upload-file local-dataverse-manifest.json

## Installing the tool in Docker:

This is used primarily for development work (where dataverse is also running in docker)

From the scripts/docker directory run the setup-datacurationtool.sh (make sure Dataverse is running so the settings api will work)

- ./setup-datacurationtool.sh

This script will build the image for the tool directly from GitHub. The script is not designed to install a specific release version.
