#!/bin/bash

AMI_ID=ami-09c813fb71547fc4f
SG_ID="sg-sg-081d2f048f93f433e" # replace with ypur security group ID
INSTANCES=("mongodb" "catalogue" "cart" "user" "shipping" "payment" "frontend" "rabbitmq" "dispatch" "mysql" "redies" )
ZONE_ID="Z0814915TW9IOIAFJ3HM" # replace with your zone ID
DOMAIN_NAME="spandanas.click" # replace with your domain name


for instance in ${INSTANCES[@]}
do 

       INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.
       micro --security-group-ids sg-081d2f048f93f433e --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)
                  if [ $instance != "frontend" ]
                  then
                    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].
                    Instances[0].PrivateIpAddress" --output text)
                    
                    else
                        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].
                    Instances[0].PublicIpAddress" --output text)
                    fi
                    echo "$instance IP address: $IP"
                 done
