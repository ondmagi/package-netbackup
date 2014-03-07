#!/bin/bash
#
# nb_extract_client.sh
#
# Script used to extract client packages from a NetBackup Master server.
#
# Requirements:
# - NetBackup Master server with supported clients available
# - fpm installed (gem install fpm)
#
# author: johan.x.wennerberg@ericsson.com
# version: 0.1
#
# CHANGES:
#   Andreas Skarmutsos Lindh 2014-03-07: Restructure to fit local needs
#   better. Added optional destdir.
#

PATH="/bin:/usr/bin/"

usage () {
    echo "Usage: `basename $0` <nbuinstallpath> [destination]"
    echo "NetBackup install basepath: /usr/openv/netbackup"
}


netbackup_basepath=$1
[ -z $netbackup_basepath ] && (usage ; exit 1)

dest=$2
if [ -z $dest ]; then
  dest=/tmp
fi

netbackup_clients=$netbackup_basepath/client
netbackup_bin=$netbackup_basepath/bin

client_types=`for type in $netbackup_clients/*; do basename $type; done`

nb_packages="SYMCnbclt:client_bin.tar.gz SYMCnbjre:JRE.tar.gz SYMCnbjava:NB-Java.tar.gz VRTSpbx:PBX.tar.gz SYMCpddea:pddeagent.tar.gz"

# Make fixer script.
# Should be run after everything else. Ugly hack for now
NBU_FIX_SCRIPT=<<EOF
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
echo "SERVER = foo.abc.com" | tee -a /usr/openv/netbackup/bp.conf
echo "CLIENT_NAME = bar.abc.com" | tee -a /usr/openv/netbackup/bp.conf
EOF

# Extracts packages and creates nbtar
for type in $client_types; do
    client_variants=`for variant in ${netbackup_clients}/${type}/*; do basename $variant; done`
    for variant in $client_variants; do
        destdir=`mktemp -d ${dest}/nbu_client_extract.XXX`
        echo "=> $variant (output to ${destdir})"
        for p in $nb_packages; do
            name=`echo $p | cut -f1 -d:`
            targz=`echo $p | cut -f2 -d:`
            echo "Extracting package ${name}"
            archive="${netbackup_clients}/${type}/${variant}/${targz}"
            if [ ! -f "${archive}" ]; then
                echo "ERROR: Could not find archive ${archive}.."
                continue
            fi
            tar xf "${archive}" -C$destdir
            case $type in
                Linux)
                    package_type="rpm"
                    case $variant in
                        SuSE2.6.16)
                            os="sles"
                            ;;
                        RedHat2.6.18)
                            os="el"
                            ;;
                    esac
                    if [ $name = 'SYMCnbclt' ]; then
                        nbclt_version=`rpm -qp --qf "%{VERSION}" ${destdir}/${name}*.rpm`
                        nbclt_release=`rpm -qp --qf "%{RELEASE}" ${destdir}/${name}*.rpm`
                        nbclt_arch=`rpm -qp --qf "%{ARCH}" ${destdir}/${name}*.rpm`
                    fi
                    package_name=`rpm -qp --qf "%{NAME}-%{VERSION}-%{RELEASE}.${os}.%{ARCH}.rpm" ${destdir}/${name}*.rpm`
                    mv ${destdir}/${name}*.rpm ${destdir}/${package_name}
                    nbtar_version=$nbclt_version
                    nbtar_release=$nbclt_release
                    nbtar_arch=$nbclt_arch
                    
                    if [ -d "${netbackup_clients}/${type}/${variant}" ]; then
                      if [ ! -f "${destdir}/NBtar-${nbtar_version}-${nbtar_release}.${os}.${nbtar_arch}.${package_type}" ]; then
                        echo "Building package NBtar.."
                        fpm -C "${netbackup_clients}/${type}/${variant}" \
                         -s dir \
                         -t $package_type \
                         -n NBtar \
                         -p ${destdir}/NBtar-${nbtar_version}-${nbtar_release}.${os}.${nbtar_arch}.${package_type} \
                         -v $nbtar_version \
                         --iteration ${nbtar_release} \
                         -a ${nbtar_arch} \
                         -m ${USER} \
                         --prefix $netbackup_bin \
                         --description "NetBackup GNU tar" \
                         --epoch $nbtar_release tar
                      fi
                    else
                        echo "ERROR: Could not find client directory.."
                    fi

                    if [ ! -f "${destdir}/NBfix-1.0-0.noarch.rpm" ]; then
                        echo "Building package NBfix.."
                        tmpd=`mktemp /tmp/postscript.XXX`
                        postfile=${tmpd}/postscript.sh
                        echo $NBU_FIX_SCRIPT | tee ${postfile}
                        fpm -C${tmpd} -s empty -t $package_type -n NBfix -p ${destdir}/NBfix-1.0-0.noarch.rpm \
                            --epoch 1.0 \
                            --iteration 0 \
                            -v 1.0 \
                            -a noarch \
                            -m ${USER} \
                            --after-install ${postfile} \
                            --description "Dummy package to fix NetBackup RPM install" \
                            -d SYMCnbclt -d SYMCpddea -d SYMCnbjava -d SYMCnbjre
                        rm -fr $tmpf
                    fi
                    ;;
                *)
                    continue
                    ;;
            esac
        done
    done
done