#!/bin/bash

start_time="$(date +%s)"
uptime="$(uptime)"
freemem="$(free -g)"
freedisk="$(df -h | grep '/'|sort -nr -k5)"
docroots="$(cat /etc/httpd/conf.d/*.conf |grep DocumentRoot | grep -v '#'|awk '{print $2}'|sort |uniq)"
hostname="$(hostname)"
sendmailqueue="$(mailq | tail -n1 | awk '{print $3}')"
postfixmailqueue="$(mailq | tail -n1 | awk '{print $5}')"

#Hostname
echo "Hostname: $hostname"
echo

#Uptime
echo "Uptime:"
echo "$uptime"
echo

#Free Memory
echo "Memory Usage (Gigabytes):"
echo "$freemem"
echo

#Disk Space
echo "Disk Space:"
echo "$freedisk"
echo

#backup files within docroots
echo "Gzip, xz and SQL files within docroots:"
find /var/www/*/htdocs/ -name "*.gz" -size +1M -o -name "*.xz" -size +1M -o -name "*.sql" -size +1M | grep -v 'backup_migrate'
echo

#Uncompressed sql files within /home/bmesh/ and /home/bmesh_admin
echo "Uncompressed sql files:"
find /home/bmesh_admin /home/bmesh/ -name "*.sql" -size +1M
echo

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
echo

#Memcache stats
if pgrep -x "memcached" > /dev/null;
then
    echo "Memcache Stats:"
    echo stats | nc localhost 11211 | grep 'hits\|misses\|evictions\|yields\|threads\|connections\|uptime'
else
    echo "Memcache not running"
fi
echo



## MALWARE HUNTING AND RELATED BELOW HERE ####


#PHP files in /uploads/ or /files/
echo "Searching for PHP files within /var/www/*/htdocs/wp-content/uploads/ and /var/www/*/htdocs/sites/default/files/."
echo "These are typically malicious files:"
find /var/www/*/htdocs/wp-content/uploads/ /var/www/*/htdocs/sites/default/files/ -name "*.php"

# Binaries within /var/www/ 
echo "Searching for binary files within /var/www/*"
echo "These are typically malicious files:"
find /var/www/ -type f -executable -exec file -i '{}' \; | grep 'x-executable; charset=binary'

# Files owned apache:apache  within /var/www/ 
# Note need to update this section to include OS detection (cent and deb) to include the www-data user
echo "Searching for files and directories owned apache:apache within /var/www/*"
echo "These are typically malicious. Note this portion will need filtering added as a pipe to 'grep -v' or blacklisting added to the find command."
echo "Until then, expect this to be verbose:"
find /var/www/ -user apache -group apache


#CMS Updates Listing Routine
mkdir -p /opt/scripts/
rm -rf /opt/scripts/cms_updates.txt
echo "Docroots found in /etc/httpd/conf.d/*.conf:" >> /opt/scripts/cms_updates.txt
echo "$docroots" >> /opt/scripts/cms_updates.txt
echo "Checking for Drupal/Wordpress updates. This could take awhile. Please be patient."
for docroot in $docroots; do echo ; cd "$docroot" || exit ; pwd ; wp core version  --allow-root 2>/dev/null ; wp plugin list --allow-root 2>/dev/null | grep -i 'available' ; wp theme list --allow-root 2>/dev/null | grep -i 'available' ; drush status 2>/dev/null | grep -i 'Drupal version'; drush up --security-only -n 2>/dev/null | grep -i 'SECURITY UPDATE available' ; done >> /opt/scripts/cms_updates.txt

echo "CMS updates scanning complete. Results will be in /opt/scripts/cms_updates.txt"

finish_time="$(date +%s)"

#Send Results Via Mail - commented out for testing
#mail -s 'CMS updates for $hostname' user@hostname.tld < /opt/scripts/updates.txt

echo "Time duration: $((finish_time - start_time)) secs."
