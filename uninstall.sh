#!/bin/sh

echo Removing files...

rm /etc/linksysmon.conf
rm /etc/cron.daily/linksysmon-report
rm /etc/init.d/linksysmon
rm /etc/logrotate.d/linksysmon
rm /usr/sbin/linksysmon
rm /usr/sbin/linksysmon-ez-ipupdate
rm /usr/sbin/linksysmon-ipchange
rm /usr/sbin/linksysmon-report
rm /usr/sbin/linksysmon-watch

echo Finished removinging files.
