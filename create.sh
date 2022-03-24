#!/bin/bash
aws cloudformation create-stack \
--stack-name $1 \
--template-body file://$2 \
--parameters file://$3



#aws cloudformation create-stack --stack-name stack-network --template-body file://1_network.yml --parameters file://1_network_params.json

#aws cloudformation create-stack --stack-name stack-apps --template-body file://2_servers.yml --parameters file://2_servers_params.json

#aws cloudformation create-stack --stack-name stack-db --template-body file://3_option_2_ec2_mysql.yml --parameters file://3_option_2_ec2_mysql_params.json