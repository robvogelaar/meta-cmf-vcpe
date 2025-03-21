#!/bin/sh

# Check if arguments were provided
if [ "$#" -lt 1 ]; then
    exit 1
fi


echo "processing logs.."

####[ -f "syscfg-$1.log" ] && parse-syscfg-log.py syscfg-$1.log
####[ -f "sysevent-$1.log" ] && parse-sysevent-log.py sysevent-$1.log
####[ -f "rbus-$1.log" ] && parse-rbus-log.py rbus-$1.log
####[ -f "rssfree-$1.log" ] && parse-rssfree-log.py rssfree-$1.log
####[ -f "datamodel-$1.log" ] && parse-datamodel.py datamodel-$1.log

[ -f "forkstat-$1.log" ] && parse-forkstat-log.py forkstat-$1.log

trace2html="/home/rev/git/catapult/tracing/bin/trace2html"
[ -f "forkstat-$1.log" ] && [ -f "$trace2html" ] && forkstat-catapult.py forkstat-$1.log | $trace2html /dev/stdin --output forkstat-$1-eventviewer.html

