#!/bin/bash
S3_BUCKET=catlab-digitalocean-fra1-backup
DAILY_KEEP_DAYS=7

# Run backup
echo "Running automysqlbackup"
/usr/sbin/automysqlbackup

# Upload to s3
echo "Uploading backup files to s3"
s3cmd sync /var/lib/automysqlbackup s3://$S3_BUCKET --skip-existing

# Remove old files
echo "Removing local files that are older than 3 days"
find /var/lib/automysqlbackup -type f -mtime +3 -name '*.gz' -print0 | xargs -r0 rm --

# Remove daily logs that are older than 7 days
echo "Removing $DAILY_KEEP_DAYS days old daily backups from s3"
s3cmd ls s3://$S3_BUCKET/automysqlbackup/daily/ -r | while read -r line;
  do
    createDate=`echo $line|awk {'print $1" "$2'}`
    createDate=`date -d"$createDate" +%s`
    olderThan=`date --date "$DAILY_KEEP_DAYS days ago" +%s`
    if [[ $createDate -lt $olderThan ]]
      then
        fileName=`echo $S3_BUCKET$line|awk {'print $4'}`
        #echo $fileName
        if [[ $fileName != "" ]]
          then
            echo "Removing $fileName"
            #s3cmd del "$fileName"
        fi
    fi
  done;
