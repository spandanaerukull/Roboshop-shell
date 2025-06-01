AMI_ID=ami-09c813fb71547fc4f
SG_ID="sg-081d2f048f93f433e"  # Corrected: Removed repeated "sg-" prefix
INSTANCES=("mongodb" "catalogue" "cart" "user" "shipping" "payment" "frontend" "rabbitmq" "dispatch" "mysql" "redis")
ZONE_ID="Z0814915TW9IOIAFJ3HM"  # Replace with your actual Hosted Zone ID
DOMAIN_NAME="spandanas.click"   # Replace with your actual domain

for instance in "${INSTANCES[@]}"
do
  echo "Creating instance: $instance"

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

  echo "Waiting for instance $INSTANCE_ID to be running..."
  aws ec2 wait instance-running --instance-ids $INSTANCE_ID

  if [ "$instance" != "frontend" ]; then
    IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text)
  else
    IP=$(aws ec2 describe-instances \
      --instance-ids $INSTANCE_ID \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text)
  fi

  echo "$instance IP address: $IP"

  # Optional: You can also create DNS record (Route 53) here if needed
done
