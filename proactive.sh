#!/bin/bash

start_time="$(date +%s)"
uptime="$(uptime)"
freemem="$(free -m)"
freedisk="$(df -h | grep '/'|sort -nr -k5)"
docroots="$(cat /etc/httpd/conf.d/*.conf |grep DocumentRoot | grep -v '#'|awk '{print $2}'|sort |uniq)"
hostname=$(hostname)

#Uptime
echo "Uptime:"
echo "$uptime"

#Free Memory
echo "Free Memory:"
echo "$freemem"

#Disk Space
echo "Disk Space:"
echo "$freedisk"


#CMS Updates listing Routine

mkdir -p /opt/scripts/
rm -rf /opt/scripts/updates.txt

echo "Docroots found in /etc/httpd/conf.d/*.conf:" >> /opt/scripts/updates.txt
echo "$docroots" >> /opt/scripts/updates.txt

for docroot in $docroots; do echo ; cd $docroot ; echo $(pwd) ; wp core version  --allow-root 2>/dev/null ; wp plugin list --allow-root 2>/dev/null | grep -i 'available' ; wp theme list --allow-root 2>/dev/null | grep -i 'available' ; drush status 2>/dev/null | grep -i 'Drupal version'; drush up --security-only -n 2>/dev/null | grep -i 'SECURITY UPDATE available' ; done >> /opt/scripts/updates.txt

finish_time="$(date +%s)"

mail -s 'CMS updates for $hostname' jwoodard@contegix.com < /opt/scripts/updates.txt

echo "Time duration: $((finish_time - start_time)) secs."

