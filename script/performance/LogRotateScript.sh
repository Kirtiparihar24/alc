#!/bin/sh
# Script to compress and archive daily log file
if [ ! -d log/archive ]; then
    mkdir log/archive
fi

cp log/production.log log/archive/
truncate -s 0  log/production.log
cd log/archive
tar czf "`date +%Y%m%d`_production.tar.gz" production.log
rm production.log
