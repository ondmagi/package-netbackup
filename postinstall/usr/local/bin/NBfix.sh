#!/bin/bash

for f in `find /usr/openv/lib/ /usr/openv/netbackup/bin/ -name '*_new'`; do
	old_name=$f
	new_name=`echo $old_name | sed 's/\(_$\)//g'`
	echo "Renaming $old_name => $new_name"
	mv $old_name $new_name
done

if [ ! -f /usr/openv/netbackup/bp.conf ]; then
	echo "SERVER = foo.abc.com" >> /usr/openv/netbackup/bp.conf
	echo "CLIENT_NAME = ${HOSTNAME}" >> /usr/openv/netbackup/bp.conf
else
	echo "/usr/openv/netbackup/bp.conf already exists, not overwriting"
fi

echo "Please have a look at /usr/openv/netbackup/bp.conf and set values"
echo "accordingly for your environment, after that everything should be setup"
echo "just fine.."
echo ""
echo "Relocating postscript to /usr/local/bin/NBfix.sh for future use"