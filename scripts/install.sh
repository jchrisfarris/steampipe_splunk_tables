#!/bin/bash -e

WHOAMI=`whoami`

if [ $WHOAMI != "root" ] ; then
	echo "Must run as root"
	exit 1
fi

STEAMPIPE_BIN=/usr/local/bin/steampipe

# root doesn't have /usr/local/bin in path, so need to hard code this
# Not ideal
if [ ! -x $STEAMPIPE_BIN ] ; then
	echo "Steampipe Not installed. See: https://steampipe.io/downloads"
	echo "Aborting..."
	exit 1
fi

# # Install Stuff
# yum install -y jq git awslogs

# # Enable EC2 to CloudWatch Logs
# systemctl enable awslogsd.service && systemctl start awslogsd

cat <<EOF> /etc/systemd/system/steampipe.service
[Unit]
Description=Steampipe
After=network.target

[Service]
Environment=STEAMPIPE_INSTALL_DIR=/home/ec2-user/.steampipe STEAMPIPE_LOG_LEVEL=INFO
Type=forking
Restart=no
# RestartSec=5
User=ec2-user
# ExecStartPre=
ExecStart=$STEAMPIPE_BIN service start
# ExecStartPost
ExecStop=$STEAMPIPE_BIN service stop
# ExecReload=

[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable steampipe
systemctl start steampipe
