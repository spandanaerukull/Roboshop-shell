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

dnf module disable nginx -y
VALIDATE $? "Disabling Default Nginx"
dnf module enable nginx:1.24 -y
VALIDATE $? "Enabling Nginx 1.24"

dnf install nginx -y
VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default Nginx content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend"


rm -rf /temp/nginx/nginx.conf
VALIDATE $? "Removing default nginx conf"
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting Nginx"


