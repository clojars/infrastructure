#!/bin/sh
# Shell script to monitor or watch the disk space
# It will send an email to $ADMIN, if the (free avilable) percentage 
# of space is >= 90% 
# -------------------------------------------------------------------------
# Copyright (c) 2005 nixCraft project <http://cyberciti.biz/fb/>
# This script is licensed under GNU GPL version 2.0 or above
# -------------------------------------------------------------------------
# This script is part of nixCraft shell script collection (NSSC)
# Visit http://bash.cyberciti.biz/ for more information.
# ----------------------------------------------------------------------
# Linux shell script to watch disk space (should work on other UNIX oses )
# SEE URL: http://www.cyberciti.biz/tips/shell-script-to-watch-the-disk-space.html
# set admin email so that you can get email
ADMIN="contact"
# set alert level 90% is default
ALERT=90
df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 " " $3 " " $4 }' | while read output;
do
  #echo $output
  usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
  partition=$(echo $output | awk '{ print $2 }' )
  used=$(echo $output | awk '{ print $3 }' )
  avail=$(echo $output | awk '{ print $4 }' )
  if [ $usep -ge $ALERT ]; then
    echo "Running out of space on ${partition} (${usep}%, used: ${used}, avail: ${avail}) on $(hostname) as of $(date)" | 
     mail -s "[ALERT] Almost out of disk space ${usep}%" $ADMIN
  fi
done
