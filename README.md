package-netbackup
=================

Scripts to extract and package NetBackup


## Requirements

* fpm (gem install fpm, requires ruby)
* rpm
* rpmbuild

## How?

1. ``./package-nbuclient.sh /usr/openv/netbackup [output path (default: /tmp)]``. This will generate generic packages.
2. Make sure to edit /usr/openv/netbackup/bp.conf accordingly (probably just change the server section)

## NBfix

Meta package handling post install tasks. Will set ``CLIENT_NAME`` in ``bp.conf`` to hostname of the server where the package is installed.

## Known limitations

Does __not__ unpack older clients (as in *RedHat2.6*, *SuSE2.6*), however the newer ones listed below works fine at the moment.

Extractable (tested) clients:

* RedHat2.6.18
* SuSE2.6.16
