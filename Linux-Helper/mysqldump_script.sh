#!/bin/bash
cd /root/glpiuser/backup
echo “You are In Backup Directory”

Now=$(date +%d-%m-%Y--%H:%M:%S)

File=$Now.sql

mysqldump –u root --all-databases > $File

echo “Your Database Backup Successfully Completed”