#!/bin/bash

USERID=$(id -u)
R=\e[31m"
G=\e[32m"
Y=\e[33m"
N=\e[0m"
LOGS_FOLDER="/var/log/roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "," -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo -e "Script started executing at: $(date)" |tee -a $LOG_FILE

#check the user has root privileges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR:: please run this script with root access $N" |tee -a $LOG_FILE 
    exit 1 # give other than 0  up to 127
else  
    echo -e " You are running with root access " |tee -a $LOG_FILE
fi

#validate function takes inputs as exit statis, what command they tried to install
VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e " $2 is ...$G success $N" |tee -a $LOG_FILE
    else
        echo -e " $2 is ..$R failure $N" |tee -a $LOG_FILE
    exit 1
    fi
}

dnf  module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS:20"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; 
then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
  VALIDATE $? "Creating roboshop system user"
else
    echo -e "system user roboshop already created ...$Y skipping $N"
fi

mkdir -p /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue.zip"

rm -rf /app/* &>>$LOG_FILE
cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue.zip"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue 
systemctl start catalogue &>>$LOG_FILE
VALIDATE $? "Starting catalogue" 

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y
VALIDATE $? "Installing MongoDB client"

STATUS=$(mongosh --host mongodb.spandanas.click --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [$STATUS -ne 1 ];
 then
  mongosh --host mongodb.spandanas.click </app/db/master-data.js &>>$LOG_FILE
VALIDATE $? "loading data into Mongodb"
else
  echo -e "$Y Data already loaded ...$ SKIPPING $N"
fi




