#!/bin/bash
# 
# NBfix.sh
#
# Post installation tasks for NetBackup client
#
# Author: Andreas Lindh <andreas@superblock.se>
# Version: 0.1
#

bpconf_path=/usr/openv/netbackup/bp.conf

for f in `find /usr/openv/lib/ /usr/openv/netbackup/bin/ -name '*_new'`; do
	old_name=$f
	new_name=`echo $old_name | sed 's/\(_new$\)//g'`
	echo "Renaming $old_name => $new_name"
	mv $old_name $new_name
done

if [ ! -f ${bpconf_path} ]; then
	echo "SERVER = not_configured" >> ${bpconf_path}
	echo "CLIENT_NAME = ${HOSTNAME}" >> ${bpconf_path}
else
	echo "${bpconf_path} already exists, not overwriting"
fi

if ! grep -q "not_configured" ${bpconf_path}; then
	echo "Please have a look at ${bpconf_path} and set values"
	echo "accordingly for your environment. Afterwards, please start the"
	echo "NetBackup services by issuing /etc/init.d/netbackup start."
	echo "You might need to run /etc/init.d/vxpbx_exchanged start"
	echo ""
	echo "Relocating postscript to /usr/local/bin/NBfix.sh for future use"
else
	echo "Looks like you have already configured ${bpconf_path}"
	echo "Will now try to restart NetBackup & VRTSpbx services"
	/etc/init.d/netbackup stop
	/etc/init.d/vxpbx_exchanged stop
	/etc/init.d/netbackup start
	/etc/init.d/vxpbx_exchanged start
fi