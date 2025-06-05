#!/bin/bash
START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
B="\e[34m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
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

echo  "Enter MySQL root password to setup"
read -s MYSQL_ROOT_PASSWORD

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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven and java"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ];
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
    else
        echo -e "system user roboshop already created ...$Y skipping $N"
    fi

mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping"

rm -rf /app/* 
cd /app
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "packaging shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "moving and renaming jar files"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon Realoding"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling shipping service"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL"

mysql -h mysql.spandanas.click --u   root -p$MYSQL_ROOT_PASSWORD -e 'use cities'$LOG_FILE

if [ $? -ne 0 ]
then

mysql -h mysql.spandanas.click --uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
mysql -h mysql.spandanas.click --uroot  -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
mysql -h mysql.spandanas.click --uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
VALIDATE $? "loading data into MySQL"

else
    echo -e "Data is already loaded int mysol...$Y SKIPPING $N" 
fi

systemctl Restart shipping &>>$LOG_FILE
Validate $? "Restarting shipping service"   


END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "Script  exection completed successfully, $Y time taken: $TOTAL_Time $N" | tee -a $LOG_FILES
