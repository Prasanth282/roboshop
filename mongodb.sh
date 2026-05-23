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

cp mongodb /etc/yum.repos.d/mongo.repo 
VALIDATE $? "copying mongo.repo"

dnf install mongodb-org -y   | tee -a $LOG_FILE
VALIDATE $? "installing mongodb"

systemctl enable mongod
VALIDATE $? "enabling mongodb"

systemctl start mongod
VALIDATE $? "starting mongodb"

sed -i 's/127.0.0.0/0.0.0.0/g' /etc/mongod.conf 
VALIDATE $? "allowing remote access to mongodb"

systemctl restart mongod 
VALIDATE $? "restarting mongodb"







