#!/bin/bash
##############################################################################
#		Written by Tim Honker
#		Originally written 8/22/2019 
#		Last updated 1/31/2020
#	References:
#	https://stackoverflow.com/questions/9904980/variable-in-bash-script-that-keeps-it-value-from-the-last-time-running
#	https://marcelog.github.io/articles/aws_get_tags_from_inside_instance_ec2.html
##############################################################################
AWS_REGION="us-east-1"
INSTANCE_TYPE="t3a.small"
AMI="ami-04763b3055de4860b"			# Ubuntu 16.04 64-bit x86
KEYPAIR="aws-marketplace-testing1"
BOOTSTRAP_SCRIPT_FILENAME="file://make_ubuntu_server.sh"
SECURITY_GROUP="sg-0338d104836ccd813"
SUBNET_ID="subnet-0c1fcfd14bc1aa8df"
COUNTER_FILE="$HOME/.counter.dat"

# if we don't have a file, start at zero
if [ ! -f "$COUNTER_FILE" ] ; then
  AWS_INSTANCE_COUNTER=0
# otherwise read the value from the file
else
  AWS_INSTANCE_COUNTER=$(cat "$COUNTER_FILE")
fi
# increment the value
AWS_INSTANCE_COUNTER=$(( AWS_INSTANCE_COUNTER + 1))
# and save it for next time
echo "${AWS_INSTANCE_COUNTER}" > "$COUNTER_FILE"

INSTANCE_NAME="AutoServer$AWS_INSTANCE_COUNTER"

#	Launching an instance that uses the bootstrap script:
aws ec2 run-instances \
--region "$AWS_REGION" \
--count 1 \
--instance-type "$INSTANCE_TYPE" \
--image-id "$AMI" \
--key-name "$KEYPAIR" \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Route53FQDN,Value=$INSTANCE_NAME.timhonker.com},{Key=Billing,Value=Rapid7Testing},{Key=GeneratedBy,Value=create_new_ec2_bootstrapped_server}]"  \
--iam-instance-profile Name=EC2-DescribeAllInstanceTagsOnly  \
--security-group-ids "$SECURITY_GROUP"  \
--subnet-id "$SUBNET_ID" \
--user-data "$BOOTSTRAP_SCRIPT_FILENAME"

echo "$INSTANCE_NAME"

echo "waiting for DNS..."
sleep 40
nslookup "$INSTANCE_NAME.timhonker.com" ns-644.awsdns-16.net

#TODO: wait in loop to initiate SSH session, DNS lookup, or pull CNAME public IP from API query
#TODO: remotely tail log