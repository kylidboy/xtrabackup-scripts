#!/usr/bin/env bash

backup_dir=/home/db-backup
week_num=$(date +%Y%U)
log_path=/var/log/innobackupex.log

# keep backup for 2 weeks
function retention {
    for week in $backup_dir/*; do
        past_week=$(basename $week)
        gap=$(($week_num - $past_week))
        if [ $gap -gt 2 ]; then
            if [ -d $week ]; then
                rm -rf $week
            fi
        fi
    done
}

if [ ! -f "$log_path" ]; then
    touch $log_path
fi

if [ -d "${backup_dir}/${week_num}" ]; then
    if [ ! -d "${backup_dir}/${week_num}/incremental" ]; then
        mkdir -p "${backup_dir}/${week_num}/incremental" >> $log_path
        if [ $? -ne 0 ]; then
            echo "fail to mkdir: ${backup_dir}/${week_num}/incremental" >> $log_path
            exit 3
        fi
    fi

    backup_base_dir=$(ls "${backup_dir}/${week_num}/" | grep -v incremental)
    if [ -d "${backup_dir}/${week_num}/${backup_base_dir}" ]; then
        innobackupex --user=xxxx --password='xxxxxxx' --incremental "${backup_dir}/${week_num}/incremental" --incremental-basedir="${backup_dir}/${week_num}/${backup_base_dir}" >> $log_path 2>&1
        if [ $? -ne 0 ]; then
            echo "incremental back up failed"
            exit 3
        fi
    else
        echo "${backup_dir}/${week_num}/${backup_base_dir} doesn't exist" >> $log_path
    fi
else
    mkdir -p "${backup_dir}/${week_num}"
    if [ $? -ne 0 ]; then
        echo "fail to mkdir: ${backup_dir}/${week_num}" > $log_path
        exit 2
    fi

    innobackupex --user=xxxx --password='xxxxxx' "${backup_dir}/${week_num}" > $log_path 2>&1
    if [ $? -ne 0 ]; then
        echo "back up failed" > $log_path
        exit 2
    fi
fi

retention
