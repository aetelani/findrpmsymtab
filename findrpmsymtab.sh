#!/bin/bash
# Copyright (C) Jarkko Sakkinen <jarkko.sakkinen@iki.fi> 2013

RPMSYMTMP=/tmp/rpmsym-$(uuid)
POPD=0

function do_exit 
{
    if [ $POPD -eq 1 ]; then
	popd > /dev/null
    fi
    chmod -R u+w $RPMSYMTMP
    rm -rf $RPMSYMTMP
    exit $1
}

trap do_exit SIGHUP SIGINT SIGTERM

mkdir $RPMSYMTMP || do_exit 1
pushd $RPMSYMTMP > /dev/null || do_exit 1
POPD=1

for package in $2/*.rpm; do
    (rpm2cpio "$package"|cpio -id) 2> /dev/null || do_exit 1
    package_name=`basename $package`
    find $RPMSYMTMP -type f -executable -print0 | \
         xargs -0 -I{} nm --format="posix" {} 2> /dev/null | \
	 grep $1 | awk -v name=$package_name '{print name ": " $1}'
    chmod -R u+w $RPMSYMTMP
    rm -rf $RPMSYMTMP/*
done

do_exit 0
