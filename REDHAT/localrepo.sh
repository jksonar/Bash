#!/bin/bash

# script to setup local repository for RED HAT 9 
if [ -d /var/repo ]
then
mount /dev/sr0 /var/repo
else
mkdir /var/repo
mount /dev/sr0 /var/repo
fi


cat > /etc/yum.repos.d/rhel9-local.repo << EOF
[Local-BaseOS]
name=Red Hat Enterprise Linux 9 - BaseOS
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///var/repo/BaseOS/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
[Local-AppStream]
name=Red Hat Enterprise Linux 9 - AppStream
metadata_expire=-1
gpgcheck=1
enabled=1
baseurl=file:///var/repo/AppStream/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
EOF