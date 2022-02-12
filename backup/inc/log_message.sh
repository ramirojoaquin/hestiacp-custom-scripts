LOG_TIME=`date +%s`
LOG_FILE=/var/log/scripts/backup/all.log
SCRIPT_NAME=`basename $0`
echo "$(date -u -d @${LOG_TIME} +'%Y-%m-%d %H:%M:%S') - $SCRIPT_NAME $@" >> $LOG_FILE
