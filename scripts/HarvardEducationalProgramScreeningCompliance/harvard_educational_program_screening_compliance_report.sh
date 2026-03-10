#!/bin/bash

OUTPUT=$PWD/harvard_educational_program_screening_compliance_report.txt
BODY=$PWD/harvard_educational_program_screening_compliance_report.body
TEMPFILE=$PWD/harvard_educational_program_screening_compliance_report.csv
HOST=dataverse-prod.cyfmiq8kmolc.us-east-1.rds.amazonaws.com
DATABASE=dvndb
USER=dvnapp

rm -rf $TEMPFILE
rm -rf $OUTPUT
rm -rf $BODY

previous_month=$(date -d "$THIS_MONTH_START -1 month" +"%B %Y")
#HOST=localhost
#DATABASE=dataverse
#USER=dataverse
#previous_month="February 2026"
echo "$previous_month"

echo "Harvard Educational Program Screening Compliance Report for $previous_month" > $BODY

psql -h $HOST -d $DATABASE -U $USER -c "SELECT useridentifier, email, affiliation FROM authenticateduser WHERE createdtime >= DATE_TRUNC('month', CURRENT_TIMESTAMP) - INTERVAL '1 month' AND createdtime < DATE_TRUNC('month', CURRENT_TIMESTAMP);" > $TEMPFILE

echo "Harvard Educational Program Screening Compliance" > $OUTPUT
echo "" >> $OUTPUT
echo $previous_month >> $OUTPUT
echo "" >> $OUTPUT
cat  $PWD/temp.csv >> $OUTPUT
mail -s "Harvard Educational Program Screening Compliance for $previous_month" -a $OUTPUT RCP_exportcontrol@harvard.edu -c steven_winship@iq.harvard.edu < $BODY


