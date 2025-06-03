#!/bin/bash

USERID=$(id -u)
R=\e[31m"
G=\e[32m"
Y=\e[33m"
N=\e[0m"
LOGS_FOLDER="/var/log/roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "," -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

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

cp mongo.repo /etc/yum.repos.d/mongodb.repo
VALIDATE $? "copying MongoBD  repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "installing MongoDB server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "enabling MongoDB service"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "starting MongoDB service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing Mongodb conf files for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "restarting MongoDB"
