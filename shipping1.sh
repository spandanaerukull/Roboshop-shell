#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)

# Color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Logging setup
LOGS_FOLDER="/var/log/roboshop"
SCRIPT_NAME=$(basename $0)
LOG_FILE="$LOGS_FOLDER/${SCRIPT_NAME%.sh}.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo -e "Script started executing at: $(date)" | tee -a $LOG_FILE

# Check for root access
if [ $USERID -ne 0 ]; then
  echo -e "$R ERROR: Please run this script as root $N" | tee -a $LOG_FILE
  exit 1
else
  echo -e "$G You are running with root access $N" | tee -a $LOG_FILE
fi

# Read MySQL root password securely
echo "Enter MySQL root password to setup:"
read -s MYSQL_ROOT_PASSWORD

# Validation function
VALIDATE() {
  if [ $1 -eq 0 ]; then
    echo -e "$2 is ... $G success $N" | tee -a $LOG_FILE
  else
    echo -e "$2 is ... $R failure $N" | tee -a $LOG_FILE
    exit 1
  fi
}

# Install Maven and Java
dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven and Java"

# Create roboshop user if not exists
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating roboshop system user"
else
  echo -e "System user roboshop already created ... $Y skipping $N" | tee -a $LOG_FILE
fi

# Setup application directory
mkdir -p /app
VALIDATE $? "Creating /app directory"

# Download and unzip shipping app
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping.zip"

rm -rf /app/*
cd /app

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping shipping.zip"

# Build Java application
mvn clean package &>>$LOG_FILE
VALIDATE $? "Packaging shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Moving and renaming JAR file"

# Setup shipping systemd service
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying shipping.service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reloading"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling shipping service"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting shipping service"

# Install MySQL client
dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL client"

# Load MySQL data (validate each step)
mysql -h mysql.spandanas.click -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
VALIDATE $? "Loading schema.sql into MySQL"

mysql -h mysql.spandanas.click -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
VALIDATE $? "Loading app-user.sql into MySQL"

mysql -h mysql.spandanas.click -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
VALIDATE $? "Loading master-data.sql into MySQL"

# Restart shipping service after DB is loaded
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting shipping service"

# Final script time summary
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Script execution completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
