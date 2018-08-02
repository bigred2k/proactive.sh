#!/bin/bash

start_time="$(date +%s)"
uptime="$(uptime)"
freemem="$(free -m)"
freedisk="$(df -h | grep '/'|sort -nr -k5)"
docroots="$(cat /etc/httpd/conf.d/*.conf |grep DocumentRoot | grep -v '#'|awk '{print $2}'|sort |uniq)"
hostname="$(hostname)"
sendmailqueue="$(mailq | tail -n1 | awk '{print $3}')"
postfixmailqueue="$(mailq | tail -n1 | awk '{print $5}')"

#Uptime
echo "Uptime:"
echo "$uptime"

#Free Memory
echo "Free Memory:"
echo "$freemem"

#Disk Space
echo "Disk Space:"
echo "$freedisk"

#Mail Queue
if pgrep -x "master" > /dev/null;
then
    echo "Postfix Queue: $postfixmailqueue"
elif pgrep -x "sendmail" > /dev/null;
then
    echo "Sendmail Queue: $sendmailqueue"
else
    echo "Unknown Mail System"
fi

#CMS Updates listing Routine

mkdir -p /opt/scripts/
rm -rf /opt/scripts/updates.txt

echo "Docroots found in /etc/httpd/conf.d/*.conf:" >> /opt/scripts/updates.txt
echo "$docroots" >> /opt/scripts/updates.txt

for docroot in $docroots; do echo ; cd $docroot ; echo $(pwd) ; wp core version  --allow-root 2>/dev/null ; wp plugin list --allow-root 2>/dev/null | grep -i 'available' ; wp theme list --allow-root 2>/dev/null | grep -i 'available' ; drush status 2>/dev/null | grep -i 'Drupal version'; drush up --security-only -n 2>/dev/null | grep -i 'SECURITY UPDATE available' ; done >> /opt/scripts/updates.txt

finish_time="$(date +%s)"

#Send Results Via Mail
#mail -s 'CMS updates for $hostname' jwoodard@contegix.com < /opt/scripts/updates.txt

echo "Time duration: $((finish_time - start_time)) secs."

