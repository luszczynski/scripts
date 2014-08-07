#!/bin/bash

JBOSS_HOME="/opt/jboss/jboss-eap-6.1"

CLI_USER="admin"
CLI_PASSWD="R3dhat!!!"
DOMAIN_CONTROLLER_IP="192.168.42.1"

# Get All Hosts
function getAllHosts(){
	TMP_HOSTS=$($JBOSS_HOME/bin/jboss-cli.sh --user=$CLI_USER --password=$CLI_PASSWD --controller=$DOMAIN_CONTROLLER_IP --connect ":read-children-names(child-type=host)" | grep -Po '".*?"' | grep -v "outcome" | grep -v "success" | grep -v "result" | tr -d '"' | tr -s '\n' ' ')

	HOSTS=($TMP_HOSTS)
}

# Get all hosts servers
function getAllServers(){
	TMP_SERVERS=$($JBOSS_HOME/bin/jboss-cli.sh --user=$CLI_USER --password=$CLI_PASSWD --controller=$DOMAIN_CONTROLLER_IP --connect "/host=$1:read-children-names(child-type=server)" | grep -Po '".*?"' | grep -v "outcome" | grep -v "success" | grep -v "result" | tr -d '"' | tr -s '\n' ' ')
	
	SERVERS=($TMP_SERVERS)
}

# Get all servers apps
function getAllApps(){
	TMP_APPS=$($JBOSS_HOME/bin/jboss-cli.sh --user=$CLI_USER --password=$CLI_PASSWD --controller=$DOMAIN_CONTROLLER_IP --connect  "/host=$1/server=$2:read-children-names(child-type=deployment)" | grep -Po '".*?"' | grep -v "outcome" | grep -v "success" | grep -v "result" | tr -d '"' | tr -s '\n' ' ')

	APPS=($TMP_APPS)
}


function checkSession(){

	QTD_ACTIVE_SESSION=1;

	while [ $QTD_ACTIVE_SESSION -ge 1 ]; do

        	QTD_ACTIVE_SESSION=$($JBOSS_HOME/bin/jboss-cli.sh --user=$CLI_USER --password=$CLI_PASSWD --controller=$DOMAIN_CONTROLLER_IP --connect "/host=$1/server=$2/deployment=$3/subsystem=web:read-attribute(name=active-sessions)" | grep result | cut -d">" -f2 | tr -d " ")
        	echo "Current Active Sessions on Application: $appname at $server: $QTD_ACTIVE_SESSION"

        	if [ ! -z $QTD_ACTIVE_SESSION ]; then
                	if [ "$QTD_ACTIVE_SESSION"  == "0" ]; then
				echo "Stopping app $4 at"
				echo "HOST => $1"
				echo "SERVER => $2"
                		$JBOSS_HOME/bin/jboss-cli.sh --user=$CLI_USER --password=$CLI_PASSWD --controller=$DOMAIN_CONTROLLER_IP --connect "/host=$1/server-config=$2:stop"
                	fi
        	fi

		sleep 5;

	done
}

echo "Inform The Application Name:"
read appname;

getAllHosts

for host in ${HOSTS[*]}
do

	echo "Looking for servers with $appname deployed at host: $host ...";

	getAllServers $host
	
	for server in ${SERVERS[*]}
	do
		getAllApps $host $server
	
		for app in ${APPS[*]}
		do
            		if [ "$appname" == "$app" ]; then
                		echo "Found $appname deployed at $server ...";
                		echo "Monitoring Active Sessions on $appname at $server ...";

				checkSession $host $server $appname $app &

			fi
		done

	done
	
done
