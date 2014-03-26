package-netbackup
=================

Scripts to extract and package NetBackup


## Requirements

* fpm (gem install fpm, requires ruby)
* rpm

## How?

``./package-nbuclient.sh /usr/openv/netbackup/client [output path (default: /tmp)]``

This will generate generic packages.

## NBfix

Meta package handling post install tasks. Will set ``CLIENT_NAME`` in ``bp.conf`` to hostname of the server where the package is installed.
