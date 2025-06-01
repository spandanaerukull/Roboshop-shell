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
VALIDATE $? "Disabling default NodeJS module"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20 module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS:20"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating roboshop system user"

mkdir /app
VALIDATE $? "Creating /app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue.zip"

cd /app
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue.zip"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading systemd daemon"

systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enabling catalogue service"

systemctl restart catalogue &>>$LOG_FILE
VALIDATE $? "Restarting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB client"

mongosh --host mongodb.spandanas.click </app/db/master-data.js &>>$LOG_FILE

