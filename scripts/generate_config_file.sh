#!/bin/bash

AWSDIR=/home/ec2-user/.aws
STEAMPIPE_CONFIG_DIR=/home/ec2-user/.steampipe/config

AUDITROLE="$1"


CREDSFILE=$AWSDIR/config
CONFIG_FILE=$STEAMPIPE_CONFIG_DIR/aws.spc

if [ -z $AUDITROLE ] ; then
	echo "Usage: $0 <AUDITROLE>"
	exit 1
fi

if [ ! -d $AWSDIR ] ; then
  mkdir -p $AWSDIR
fi

if [ ! -d $STEAMPIPE_CONFIG_DIR ] ; then
  mkdir -p $STEAMPIPE_CONFIG_DIR
fi

echo "# Automatically Generated at `date`" > $CONFIG_FILE
echo "# Automatically Generated at `date`" > $CREDSFILE

# Make sure we have the default region set
cat <<EOF>>$CREDSFILE
[default]
region = us-east-1

EOF

# TODO, do we need to (or can we) set sane defaults in the generic aws connection?

# This will iterate across the `aws organizations list-accounts` command
while read line ; do

  # extract the values we need
  ACCOUNT_NAME=`echo $line | awk '{print $1}'`
  ACCOUNT_ID=`echo $line | awk '{print $2}'`

  # Steampipe doesn't like dashes, so we need to swap for underscores
  SP_NAME=`echo $ACCOUNT_NAME | sed s/-/_/g`

# Append an entry to the AWS Creds file
cat <<EOF>>$CREDSFILE

[$ACCOUNT_NAME]
role_arn = arn:aws:iam::$ACCOUNT_ID:role/$AUDITROLE
# source_profile = default
EOF

# And append an entry to the Steampipe config file
cat <<EOF>>$CONFIG_FILE
connection "aws_$SP_NAME" {
  plugin  = "aws"
  profile = "$ACCOUNT_NAME"
  regions = ["us-east-1"]  # FIXME SOMEDAY
    options "connection" {
        cache     = true # true, false
        cache_ttl = 3600  # expiration (TTL) in seconds
    }
}

EOF

# Add the account to a list
ACCOUNTS="$ACCOUNTS aws_$SP_NAME "

done < <(aws organizations list-accounts --query Accounts[].[Name,Id,Status] --output text)


# Now we need to create a single search aggregation for all the AWS accounts
# and add it to the config file
AGG=`echo $ACCOUNTS | tr -d '\n' | jq -R -s -c 'split(" ")'`
cat <<EOF>>$CONFIG_FILE

connection "aws_all" {
  plugin      = "aws"
  type        = "aggregator"
  connections = $AGG
}

EOF

# All done!
exit 0