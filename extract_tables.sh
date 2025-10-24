#!/bin/bash

if [ $# -lt 2 ]; then
  echo 'You must specify the DB host, port and username'
  echo '    (e.g. ./extract_tables.sh 127.0.0.1 3306 root)'
  exit 1
fi

SCHEMA=migration

TABLES=$(mysql -h $1 -P $2 -u $3 -p -Nse \
"SELECT TABLE_NAME
 FROM information_schema.tables
 WHERE TABLE_SCHEMA='$SCHEMA'
   AND TABLE_TYPE='BASE TABLE';")

mysqldump -h 127.0.0.1 -P 3308 -u cdlawsdba -p dmp --single-transaction --quick --skip-lock-tables --lock-tables=false --set-gtid-purged=OFF > ~/source_db.sql
