#!/bin/bash
##############################################################################
#		Written by Tim Honker
#		Originally written 8/21/2019 late at night with a few glasses of wine
#
#		Installs Apache and serves a webpage that describes
#		EC2 instance information. For use with identifying servers
#		behind load balancers
#		Intended to be a boot strap script for use in USER DATA
#		for AWS EC2 instances.
#
#		Note: this only runs on the initial power on and not on 
#		reboots or subsequent starts. It does not run as a cron either.
#	
#		Requirements: this EC2 instanace to have a role that has
#			a policy that allows use of ec2-describe-tags and ec2-describe-instances
#
# 	Documentation links
#		curl http://169.254.269.254/
#		https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html
#		https://aws.amazon.com/code/ec2-instance-metadata-query-tool/
#		https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-tags.html
#		https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html
#		https://docs.aws.amazon.com/cli/latest/userguide/cli-usage-output.html
#		https://www.thegeekstuff.com/2017/07/aws-ec2-cli-userdata/
#
##############################################################################

yum update -y

# set the time zone as US EAST
echo "ZONE=America/New_York
UTC=true" > /etc/sysconfig/clock
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

yum install httpd -y
service httpd start
chkconfig httpd on

rm -f /var/www/html/index.html

AWS_REGION=$(ec2-metadata --availability-zone | cut -d " " -f2 | sed 's/.$//')
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f2)

# logic seems to be breaking things
#if aws ec2 describe-tags --region $AWS_REGION --dry-run; then
#	#this seems to come back blank for some reason, can't get it to error
#    NAME_TAG="IAM Role not assigned, can't use aws command. Please grant this EC2 instance the ability to view tags"
#    VPC_ID=$NAME_TAG
#    SUBNET_ID=$NAME_TAG
#else

	NAME_TAG=$(aws ec2 describe-tags --region $AWS_REGION --filters "Name=resource-id,Values=${INSTANCE_ID}" | grep -2 Name | grep Value | tr -d ' ' | cut -f2 -d: | tr -d '"' | tr -d ','
)
	VPC_ID=$(aws ec2 describe-instances    --region $AWS_REGION --instance-ids $INSTANCE_ID --output text --query "Reservations[0].Instances[0].VpcId")
	SUBNET_ID=$(aws ec2 describe-instances --region $AWS_REGION --instance-ids $INSTANCE_ID --output text --query "Reservations[0].Instances[0].SubnetId")
#fi

# I know there's a much easier way to dump all this into a text file, but I was lazy

echo "<html><body><h1>Server Name Tag: $NAME_TAG </h1></p>" 		>  /var/www/html/index.html
echo "Timestamp of when created: " $(date) "</p>"	>> /var/www/html/index.html
echo "Region    : $AWS_REGION </p>"				    >> /var/www/html/index.html
echo "VPC Id    : $VPC_ID </p>"						>> /var/www/html/index.html
echo "Subnet Id : $SUBNET_ID </p>" 					>> /var/www/html/index.html
echo $(ec2-metadata --local-hostname) 	 "</p>"		>> /var/www/html/index.html 
echo $(ec2-metadata --local-ipv4) 		 "</p>"		>> /var/www/html/index.html 
echo $(ec2-metadata --availability-zone) "</p>" 	>> /var/www/html/index.html 
echo $(ec2-metadata --public-hostname)   "</p>"		>> /var/www/html/index.html 
echo $(ec2-metadata --public-ipv4)   	 "</p>"		>> /var/www/html/index.html 
echo $(ec2-metadata --security-groups)   "</p>"		>> /var/www/html/index.html 
echo $(ec2-metadata --instance-id)       "</p>"		>> /var/www/html/index.html 
echo $(ec2-metadata --instance-type)     "</p>"		>> /var/www/html/index.html 
#echo "Uptime: " $(uptime)     	 		 "</p>"		>> /var/www/html/index.html 
echo "</p></body></html>" >> /var/www/html/index.html

# Install other things I might need
# in Amazon Linux 2 by default: screen openssl tcpdump iostat md5sum netstat vim get
yum install telnet nmap-ncat nmap -y 
