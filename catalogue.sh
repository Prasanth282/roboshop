#!/bin/bash 

R=\e[31m
G=\e[32m
N=\e[0m
Y=\e[33m

USERID=$(id -u)

if [ $USERID -ne 0 ]
then 
    echo "error :: you don't have root user privlages "
    exit 1
else
    echo " you have root user privlages "
fi 


VALIDATE() {
    if [ $1 -eq 0 ]
    then 
        echo " $2 is success "
    else 
        echo "$2 is failed "
    fi     
    

}

FOLDER_PATH="/var/log/shell-scripts"
SCRIPT_NAME="$0"
LOG_FILE="$FOLDER_PATH/$SCRIPT_NAME.log"

mkdir -p $FOLDER_PATH 

echo "script executed date is :: $(date)" | tee -a $LOG_FILE

dnf module disable nodejs -y | tee -a $LOG_FILE
VALIDATE $? "disabling nodejs module"

dnf module enable nodejs:20 -y | tee -a $LOG_FILE
VALIDATE $? "enabling nodejs module"

dnf install nodejs -y | tee -a $LOG_FILE
VALIDATE $? "installing nodejs"

mkdir -p /app 
VALIDATE $? "creating app directory"

id roboshop 
if [ $? -ne 0 ]
then 
    echo " roboshop user doesn't exist, creating it "
    useradd --system --home /app --shell /sbin/nologin --comment" roboshop user" roboshop  
    VALIDATE $? "creating roboshop user" $>>$LOG_FILE
else 
    echo " roboshop user already exists "
fi

rm -rf /app/*


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip | tee -a $LOG_FILE
VALIDATE $? "downloading catalogue code"

cd /app 
VALIDATE $? "changing directory to /app" 

unzip /tmp/catalogue.zip
VALIDATE $? "unzipping catalogue code" tee -a | tee -a $LOG_FILE

cd /app 
VALIDATE $? "changing directory to /app" 

npm install | tee -a $LOG_FILE
VALIDATE $? "installing nodejs dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue systemd service file"  | tee -a $LOG_FILE

systemctl daemon-reload
VALIDATE $? "reloading systemd daemon"  | tee -a $LOG_FILE

systemctl enable catalogue.service 
VALIDATE $? "enabling catalogue service" 

systemctl start catalogue.service 
VALIDATE $? "starting catalogue service"

cp mongodb /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo.repo" 

dnf install mongodb-mongosh -y | tee -a $LOG_FILE
VALIDATE $? "installing mongodb shell"


STATUS=$(mongosh --host mongodb.prasanth.cloud </app/db/master-data.js --eval db.getMongo().getDBNames().indexOf("catalogue"))
if [ $STATUS -lt 0 ]
then 
    echo "catalogue database is not present.. loading the data..."
    mongosh --host mongodb.prasanth.cloud </app/db/master-data.js
    VALIDATE $? "loading catalogue data to mongodb"
else 
    echo " catalogue database is already present.. skipping data load"
    
    exit 1 
fi





