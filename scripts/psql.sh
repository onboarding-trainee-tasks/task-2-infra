#!/bin/bash

DB_URL="postgresql://${DB_USERNAME}:${DB_PASSWORD}@${DB_ENDPOINT}/${DB_NAME}"

sudo apt install postgresql-client -y
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

sleep 5
aws s3 cp s3://init-sql-script/db_init.sql /home/ubuntu/db_init.sql
sleep 5
psql "$DB_URL" -f /home/ubuntu/db_init.sql