#!/bin/bash
##############################################################################
#		Written by Tim Honker
#		Originally written 8/22/2019 
#	References:
#	https://stackoverflow.com/questions/9904980/variable-in-bash-script-that-keeps-it-value-from-the-last-time-running
#	https://marcelog.github.io/articles/aws_get_tags_from_inside_instance_ec2.html
##############################################################################


# if we don't have a file, start at zero
if [ ! -f "counter.dat" ] ; then
  AWS_INSTANCE_COUNTER=0
# otherwise read the value from the file
else
  AWS_INSTANCE_COUNTER=`cat counter.dat`
fi
# increment the value
AWS_INSTANCE_COUNTER=`expr ${AWS_INSTANCE_COUNTER} + 1`
# and save it for next time
echo "${AWS_INSTANCE_COUNTER}" > counter.dat

AWS_REGION="us-west-1"
INSTANCE_TYPE="t2.nano"
INSTANCE_NAME="WebServer$AWS_INSTANCE_COUNTER"

#	Launching an instance that uses the bootstrap script:
aws ec2 run-instances \
--region $AWS_REGION \
--count 1 \
--instance-type $INSTANCE_TYPE \
--image-id ami-056ee704806822732 \
--key-name NorCal_keypair1 \
--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Project,Value=ACloudGuru},{Key=GeneratedBy,Value=create_new_ec2_bootstrapped_server}]"  \
--iam-instance-profile Name=EC2-DescribeAllInstanceTagsOnly  \
--security-group-ids sg-05f548ed8e3265ac2  \
--user-data file://bootstrap-web-server.sh

echo "$INSTANCE_NAME"
