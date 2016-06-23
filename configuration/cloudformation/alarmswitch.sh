#!/bin/bash -ex
#
# Copyright © 2016 Versent Pty. Ltd.  - All Rights Reserved
# For more details please see:
# http://versent.com.au/software-licence.html
# License subject to change at Versent's discretion.
# Contact: info@versent.com.au
#

case $1 in
disable-alarm-actions) ;;
enable-alarm-actions) ;;
*) echo "Usage: $0 [ disable-alarm-actions | enable-alarm-actions ]"; exit 1
esac

alarmprefix="[TUFMS][0] ELK"
echo "executing $1 for all alarms prefixed with $alarmprefix"
echo '{"AlarmNames":'> alarms.json
aws cloudwatch describe-alarms "--alarm-name-prefix=$alarmprefix" --query MetricAlarms[].AlarmName >> alarms.json
echo '}' >> alarms.json

aws cloudwatch $1 --cli-input-json file://alarms.json
