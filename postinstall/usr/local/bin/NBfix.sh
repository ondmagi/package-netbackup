#!/bin/bash

for f in `find /usr/openv/lib/ /usr/openv/netbackup/bin/ -name '*_new'`; do
	old_name=$f
	new_name=`echo $old_name | sed 's/\(_new$\)//g'`
	echo "Renaming $old_name => $new_name"
	mv $old_name $new_name
done

if [ ! -f /usr/openv/netbackup/bp.conf ]; then
	echo "SERVER = foo.abc.com" >> /usr/openv/netbackup/bp.conf
	echo "CLIENT_NAME = ${HOSTNAME}" >> /usr/openv/netbackup/bp.conf
else
	echo "/usr/openv/netbackup/bp.conf already exists, not overwriting"
fi

if ! grep -q "foo.abc.com" /usr/openv/netbackup/bp.conf; then
	echo "Please have a look at /usr/openv/netbackup/bp.conf and set values"
	echo "accordingly for your environment. Afterwards, please start the"
	echo "NetBackup services by issuing /etc/init.d/netbackup start."
	echo "You might need to run /etc/init.d/vxpbx_exchanged start"
	echo ""
	echo "Relocating postscript to /usr/local/bin/NBfix.sh for future use"
else
	echo "Looks like you have already configured /usr/openv/netbackup/bp.conf"
	echo "Will now try to restart NetBackup & VRTSpbx services"
	/etc/init.d/netbackup stop
	/etc/init.d/vxpbx_exchanged stop
	/etc/init.d/netbackup start
	/etc/init.d/vxpbx_exchanged start
fi