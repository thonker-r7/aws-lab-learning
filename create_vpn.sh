#!/bin/bash
##############################################################################
#	Written by Tim Honker
#	Originally written 10/29/2019
#
#	References:
#		https://github.com/t04glovern/aws-pptp-cloudformation	
#		https://apple.stackexchange.com/questions/128297/how-to-create-a-vpn-connection-via-terminal
#		https://console.aws.amazon.com/cloudformation/home?region=us-east-1#/stacks/new?stackName=pptp-vpn&templateURL=https://s3.amazonaws.com/devopstar/resources/aws-pptp-cloudformation/pptp-server.yaml
#		https://s3.amazonaws.com/devopstar/resources/aws-pptp-cloudformation/pptp-server.yaml
#
##############################################################################

CONFIG_DIRECTORY="$HOME/Documents/no_backup/aws-pptp-cloudformation"
REGION="us-east-1"

#potentially make the directory, do a git pull if necessary

# Stack name can include letters (A-Z and a-z), numbers (0-9), and dashes (-).
CURRENT_DATE=$(date +%Y-%m-%d-%H-%M-%S)
export STACK_NAME="pptp-vpn-$CURRENT_DATE"

# make this an IF statement, bomb out if can't built it
aws cloudformation create-stack --stack-name "$STACK_NAME" \
    --template-body file://$CONFIG_DIRECTORY/pptp-server.yaml \
    --parameters file://$CONFIG_DIRECTORY/pptp-server-params.json \
    --region "$REGION"

# wait and poll until the stack is finished spinning up
echo "Started stack deployment $STACK_NAME"

EXIT_STATUS="CREATE_COMPLETE"
while true
do
	STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --output text | grep "$STACK_NAME" | awk -F\t '{print $NF}' )
	if [ $STACK_STATUS == $EXIT_STATUS ]; then
	  break;
	else
	   echo "waiting on stack to start... $STACK_STATUS"
	   sleep 5
	fi
done

# store the IP
STACK_IP=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$REGION" --query 'Stacks[0].Outputs[?OutputKey==`VPNServerAddress`].OutputValue' --output text)

echo "Build finished, IP is $STACK_IP"
# TCP ports

while true
do
	PORT_STATUS=$( nmap -Pn -p 1723 $STACK_IP | grep 1723 | cut -d' ' -f2 )
	if [ $PORT_STATUS == "open" ]; then
		echo "Port is now open"
		break;
	else
	   echo "Waiting on port to open on IP... $PORT_STATUS"
	   sleep 5
	fi
done




# get list of local OS X VPNs
#scutil --nc list

#scutil --nc start Foo --user bar --password baz --secret quux
scutil --nc trigger "$STACK_IP" --user vpnuser --password C77qvgzjEQJQ8r7rtU --secret C77qvgzjEQJQ8r7rtU
# create route 53 entry for VPN

# update local Mac config to use this address or just initiate it, maybe clear DNS cache
#sudo killall -HUP mDNSResponder;say DNS cache has been flushed
#sudo dscacheutil -flushcache

# deletes all running stacks that this script creates
#STACKS_RUNNING_LIST=$(aws cloudformation describe-stacks --output text | grep CREATE_COMPLETE | grep "pptp-vpn-" | cut -d$'\t' -f6)

#for STACK_NAME_TO_TERMINATE in $STACKS_RUNNING_LIST
#do
#	echo "Deleting stack $STACK_NAME_TO_TERMINATE"
#	aws cloudformation delete-stack --stack-name "$STACK_NAME_TO_TERMINATE"
#done
