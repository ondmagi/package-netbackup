#!/bin/bash
mv /usr/openv/lib/libnbbaseST.so_new /usr/openv/lib/libnbbaseST.so
mv /usr/openv/lib/libnbbaseST32.so_new /usr/openv/lib/libnbbaseST32.so
mv /usr/openv/lib/libnbclientST.so_new /usr/openv/lib/libnbclientST.so
mv /usr/openv/lib/libnbclientST32.so_new /usr/openv/lib/libnbclientST32.so
mv /usr/openv/lib/libnbcryptowST.so_new /usr/openv/lib/libnbcryptowST.so
mv /usr/openv/lib/libnbmangle.so_new /usr/openv/lib/libnbmangle.so
mv /usr/openv/lib/libvrtsLogFormatMsgST.so.3_new /usr/openv/lib/libvrtsLogFormatMsgST.so.3
mv /usr/openv/lib/libvrtsLogReadST.so.3_new /usr/openv/lib/libvrtsLogReadST.so.3
mv /usr/openv/lib/libvrtsLogSLST.so.3_new /usr/openv/lib/libvrtsLogSLST.so.3
mv /usr/openv/lib/libvxACEST.so.6_new /usr/openv/lib/libvxACEST.so.6
mv /usr/openv/lib/libvxcPBXST.so_new /usr/openv/lib/libvxcPBXST.so
mv /usr/openv/lib/libvxcryptoST.so.5_new /usr/openv/lib/libvxcryptoST.so.5
mv /usr/openv/lib/libvxexticuST.so.3_new /usr/openv/lib/libvxexticuST.so.3
mv /usr/openv/lib/libvxicudataST.so_new /usr/openv/lib/libvxicudataST.so
mv /usr/openv/lib/libvxicui18nST.so_new /usr/openv/lib/libvxicui18nST.so
mv /usr/openv/lib/libvxicuucST.so_new /usr/openv/lib/libvxicuucST.so
mv /usr/openv/lib/libvxlisST.so.3_new /usr/openv/lib/libvxlisST.so.3
mv /usr/openv/lib/libvxsslST.so.5_new /usr/openv/lib/libvxsslST.so.5
mv /usr/openv/lib/libvxulST.so.3_new /usr/openv/lib/libvxulST.so.3
mv /usr/openv/lib/libvxustdioST.so_new /usr/openv/lib/libvxustdioST.so
mv /usr/openv/netbackup/bin/bpcd_new /usr/openv/netbackup/bin/bpcd
mv /usr/openv/netbackup/bin/vnetd_new /usr/openv/netbackup/bin/vnetd
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