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
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`

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

postfile=$PROGPATH/postinstall/usr/local/bin/NBfix.sh

# Extracts packages and creates nbtar
for type in $client_types; do
    client_variants=`for variant in ${netbackup_clients}/${type}/*; do basename $variant; done`
    for variant in $client_variants; do
        destdir=`mktemp -d ${dest}/nbu_client_${variant}__XXX`
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
                        fpm -C "${PROGPATH}/postinstall" -s dir -t rpm \
                            -n NBfix \
                            -p $destdir/NBfix-1.0-0.noarch.rpm \
                            --epoch 1 \
                            --iteration 1 \
                            -v 1.0 \
                            -a noarch \
                            -m ${USER} \
                            --after-install $postfile \
                            --description "Dummy package that fixes NetBackup RPM packages" \
                            -d 'SYMCnbclt' -d 'SYMCpddea' -d 'SYMCnbjava' -d 'SYMCnbjre' \
                            usr/local/bin/NBfix.sh
                    fi
                    ;;
                *)
                    continue
                    ;;
            esac
        done
    done
done
