#!/bin/bash

# prepare build tools
sudo apt-get update && sudo apt-get install --yes --no-install-recommends ca-certificates build-essential git libssl-dev curl cpio bspatch vim gettext bc bison flex dosfstools kmod jq

root=`pwd`
mkdir DS3615xs-7.0.1
mkdir output
cd DS3615xs-7.0.1

# download redpill
git clone --depth=1 https://github.com/RedPill-TTG/redpill-lkm.git
git clone -b develop --depth=1 https://github.com/jumkey/redpill-load.git

# download syno toolkit
curl --location "https://sourceforge.net/projects/dsgpl/files/toolkit/DSM7.0/ds.bromolow-7.0.dev.txz/download" --output ds.bromolow-7.0.dev.txz

mkdir bromolow
tar -C./bromolow/ -xf ds.bromolow-7.0.dev.txz usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build

# build redpill-lkm
cd redpill-lkm
sed -i 's/   -std=gnu89/   -std=gnu89 -fno-pie/' ../bromolow/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build/Makefile
make LINUX_SRC=../bromolow/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build dev-v7
read -a KVERS <<< "$(sudo modinfo --field=vermagic redpill.ko)" && cp -fv redpill.ko ../redpill-load/ext/rp-lkm/redpill-linux-v${KVERS[0]}.ko || exit 1
cd ..

# build redpill-load
cd redpill-load
sed -i -e 's\1234XXX123\1230LWN003637\g' -e 's\MAC1ADDRESS\245EBE0299E8\g' -e 's\MAC2ADDRESS\001B21BC18BB\g' ${root}/user_config.DS3615xs.json
cp -f ${root}/user_config.DS3615xs.json ./user_config.json
sudo ./ext-manager.sh add 'https://raw.githubusercontent.com/pocopico/rp-ext/master/mpt3sas/rpext-index.json'
sudo ./ext-manager.sh add 'https://raw.githubusercontent.com/pocopico/rp-ext/master/ixgbe/rpext-index.json'
sudo ./ext-manager.sh add 'https://raw.githubusercontent.com/pocopico/rp-ext/master/ixgbevf/rpext-index.json'
sudo ./ext-manager.sh add 'https://raw.githubusercontent.com/pocopico/rp-ext/master/igb/rpext-index.json'
sudo ./ext-manager.sh add 'https://raw.githubusercontent.com/pocopico/rp-ext/master/e1000/rpext-index.json'
sudo ./ext-manager.sh add 'https://raw.githubusercontent.com/pocopico/rp-ext/master/vmxnet3/rpext-index.json'
sudo ./build-loader.sh 'DS3615xs' '7.0.1-42218'
mv images/redpill-DS3615xs_7.0.1-4221*.img ${root}/output/
cd ${root}
