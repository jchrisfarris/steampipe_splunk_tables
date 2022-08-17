#!/bin/bash

SQL_FILE=$1
BUCKET=$2

if [ -z "$BUCKET" ] ; then
	echo "USAGE: $0 <SQL FILE> <BUCKETNAME>"
	exit 1
fi

# Lets find the SQL file relative to this script
# so I don't need full paths in the crontab
SCRIPT_PATH=`dirname "${BASH_SOURCE[0]}"`
SQL_PATH="$SCRIPT_PATH/../queries"

if [ ! -f "$SQL_FILE" ] ; then
	# Maybe they did provide a full path, in which case we don't need to do this
	SQL_FILE="$SQL_PATH/$SQL_FILE"
fi

# Try again to make sure we can find the file with the assumed path
if [ ! -f "$SQL_FILE" ] ; then
	echo "Cannot file $SQL_FILE. Aborting..."
	exit 1
fi

echo "Processing $SQL_FILE"

OUTFILE=`basename $SQL_FILE .sql `
TMPFILE=`mktemp /tmp/$OUTFILE.XXXXXXXXXX.csv`

steampipe query $SQL_FILE --output csv > $TMPFILE
aws s3 cp $TMPFILE s3://$BUCKET/lookup_tables/$OUTFILE.csv

rm $TMPFILE