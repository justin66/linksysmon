#!/bin/sh

echo Copying files...

if [ -f /etc/linksysmon.conf ] ; then
    cp ./etc/linksysmon.conf /etc/linksysmon.conf-new;
else
    cp ./etc/linksysmon.conf /etc/;
fi
cp ./etc/cron.daily/linksysmon-report /etc/cron.daily/
cp ./etc/init.d/linksysmon /etc/init.d/
cp ./etc/logrotate.d/linksysmon /etc/logrotate.d/
cp ./usr/sbin/linksysmon /usr/sbin/
cp ./usr/sbin/linksysmon-ez-ipupdate /usr/sbin/
cp ./usr/sbin/linksysmon-ipchange /usr/sbin/
cp ./usr/sbin/linksysmon-report /usr/sbin/
cp ./usr/sbin/linksysmon-watch /usr/sbin/

echo Finished copying.
