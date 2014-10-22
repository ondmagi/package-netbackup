#!/bin/bash
#
# package-nbuclient.sh
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
#   Andreas Lindh <andreas@superblock.se> 2014-03-10:
#       Create NBfix rpm which is a meta package holding post install
#       scripts etc.
#   Andreas Lindh <andreas@superblock.se> 2014-03-07:
#       Restructure to fit local needs better. Added optional destdir.
#

PATH="$PATH:/bin:/usr/bin/:/usr/local/bin"
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`
PROGDIR=`dirname $0`

usage () {
    echo "Usage: `basename $0` <nbuinstallpath> [destination]"
    echo "NetBackup install basepath: /usr/openv/netbackup"
}

FPM=`which fpm`

if [ ! -x $FPM ]; then
    echo "You must have fpm installed in order to run this script"
    exit 1
fi

netbackup_basepath=$1
if [ -z "$netbackup_basepath" ]; then
    usage
    exit 1
fi

dest=$2
if [ -z $dest ]; then
  dest=/tmp
fi
if [ ! -d "$dest" ]; then
    mkdir -p $dest
fi

netbackup_clients=$netbackup_basepath/client
netbackup_bin=$netbackup_basepath/bin

# ONLY SUPPORTED TYPES FOR NOW
#client_types=`for type in $netbackup_clients/*; do basename $type; done`
client_types="Linux"


nb_packages="SYMCnbclt:client_bin.tar.gz SYMCnbjre:JRE.tar.gz SYMCnbjava:NB-Java.tar.gz VRTSpbx:PBX.tar.gz SYMCpddea:pddeagent.tar.gz"

postfile=$PROGDIR/postinstall/usr/local/bin/NBfix.sh

# Extracts packages and creates nbtar
for type in $client_types; do
    #client_variants=`for variant in ${netbackup_clients}/${type}/*; do basename $variant; done`
    # ONLY SUPPORTED VARIANTS FOR NOW
    client_variants="RedHat2.6.18 SuSE2.6.16"

    for variant in $client_variants; do
        unpackdir=`mktemp -d ${dest}/unpack_XXX`
        for p in $nb_packages; do
            name=`echo $p | cut -f1 -d:`
            targz=`echo $p | cut -f2 -d:`
            echo "Extracting package ${name} for ${type}/${variant}"
            archive="${netbackup_clients}/${type}/${variant}/${targz}"
            if [ ! -f "${archive}" ]; then
                echo "ERROR: Could not find archive ${archive}.."
                continue
            fi
            tar xf "${archive}" -C ${unpackdir}
            mkdir -p ${dest}/${type}_${variant}
            case $type in
                Linux)
                    case $variant in
                        SuSE*)
                            os="sles"
                            distro="SUSE"
                            package_type="rpm"
                            ;;
                        RedHat*)
                            os="el"
                            distro="REDHAT"
                            package_type="rpm"
                            ;;
                    esac
                    if [ $name = 'SYMCnbclt' ]; then
                        nbclt_version=`rpm -qp --qf "%{VERSION}" ${unpackdir}/${name}*.rpm`
                        nbclt_release=`rpm -qp --qf "%{RELEASE}" ${unpackdir}/${name}*.rpm`
                        nbclt_arch=`rpm -qp --qf "%{ARCH}" ${unpackdir}/${name}*.rpm`
                    fi
                    package_name=`rpm -qp --qf "%{NAME}-%{VERSION}-%{RELEASE}.${os}.%{ARCH}.rpm" ${unpackdir}/${name}*.rpm`
                    mv ${unpackdir}/${name}*.rpm ${dest}/${type}_${variant}/${package_name}
                    nbtar_version=${nbclt_version}
                    nbtar_release=${nbclt_release}
                    nbtar_arch=${nbclt_arch}

                    version_string="NetBackup-${variant} ${nbclt_version}"
                    if [ -d "${netbackup_clients}/${type}/${variant}" ]; then
                      if [ ! -f "${dest}/${type}_${variant}/NBtar-${nbtar_version}-${nbtar_release}.${os}.${nbtar_arch}.${package_type}" ]; then
                        echo "Building package NBtar.."
                        ${FPM} -C "${netbackup_clients}/${type}/${variant}" \
                         -s dir \
                         -t ${package_type} \
                         -n NBtar \
                         -p ${dest}/${type}_${variant}/NBtar-${nbtar_version}-${nbtar_release}.${os}.${nbtar_arch}.${package_type} \
                         -v ${nbtar_version} \
                         --iteration ${nbtar_release} \
                         -a ${nbtar_arch} \
                         -m ${USER} \
                         --prefix /usr/openv/netbackup/bin \
                         --description "NetBackup GNU tar" \
                         --epoch ${nbtar_release} tar
                      fi
                    else
                        echo "ERROR: Could not find client directory.."
                    fi

                    if [ ! -f "${dest}/${type}_${variant}/NBfix-${nbtar_version}-${nbtar_release}.${os}.noarch.rpm" ]; then
                        echo "Building package NBfix.."

                        rm -f $PROGDIR/postinstall/usr/local/bin/nbuversion
                        rm -f $PROGDIR/postinstall/usr/local/bin/nbubinversion

                        echo "HARDWARE LINUX_${distro}_X86" | tee -a $PROGDIR/postinstall/usr/local/bin/nbuversion 2>&1
                        echo "VERSION NetBackup ${nbclt_version}" | tee -a $PROGDIR/postinstall/usr/local/bin/nbuversion 2>&1

                        echo "NetBackup-${variant} ${nbclt_version}" | tee -a $PROGDIR/postinstall/usr/local/bin/nbubinversion 2>&1

                        mkdir -p ${dest}/${type}_${variant}
                        ${FPM} -C "${PROGDIR}/postinstall" -s dir -t rpm \
                            -n NBfix \
                            -p ${dest}/${type}_${variant}/NBfix-${nbtar_version}-${nbtar_release}.${os}.noarch.rpm \
                            --epoch ${nbtar_release} \
                            --iteration ${nbtar_release} \
                            -v ${nbtar_version} \
                            -a noarch \
                            -m ${USER} \
                            --after-install $postfile \
                            --description "Dummy package that fixes NetBackup RPM packages" \
                            -d 'SYMCnbclt' -d 'SYMCpddea' -d 'SYMCnbjava' -d 'SYMCnbjre' \
                            usr/local/bin/
                    fi
                    ;;
                *)
                    echo "${type} platform not yet supported by `basename $0`"
                    ;;
            esac
        done
        rm -fr ${unpackdir}
    done
done
