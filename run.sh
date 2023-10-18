#!/bin/sh

ISO_URL='https://www.hirensbootcd.org/files/HBCD_PE_x64.iso'
[ -n "${ISO}" ] && ISO_URL=${ISO}

DSIZE='64G'
[ -n "${DISK_SIZE}" ] && DSIZE=${DISK_SIZE}

RSIZE='16G'
[ -n "${RAM_SIZE}" ] && RSIZE=${RAM_SIZE}

NIC='rtl8139'
[ -n "${NIC_TYPE}" ] && NIC=${NIC_TYPE}

echo "download windows server 2022 iso..."
wget "${ISO_URL}" -O /images/cdrom.iso

echo "create disk image..."
qemu-img create -f qcow2 /images/disk1.qcow2 ${DSIZE}

echo "create tmp swtpm dir and socket..."
mkdir -p /tmp/mytpm1
nohup swtpm socket --tpmstate dir=/tmp/mytpm1 --tpm2 \
    --ctrl type=unixio,path=/tmp/mytpm1/swtpm-sock \
    --log level=20 &

echo "start vm..."
qemu-system-x86_64 \
    -m ${RSIZE} -smp 8 \
    -machine q35 \
    -usb -device usb-tablet -device virtio-gpu \
    -netdev user,id=n0,hostfwd=tcp::2375-:2375 -device ${NIC_TYPE},netdev=n0 \
    -chardev socket,id=chrtpm,path=/tmp/mytpm1/swtpm-sock \
    -tpmdev emulator,id=tpm0,chardev=chrtpm \
    -device tpm-tis,tpmdev=tpm0 \
    -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=/images/OVMF_VARS.fd \
    -drive file=/images/cdrom.iso,if=ide,index=0,media=cdrom \
    -vnc :0 -k en-us \
    -drive file=/images/disk1.qcow2,if=ide,index=3,media=disk \
    -monitor stdio "$@" &

echo "start novnc proxy..."
/novnc/utils/novnc_proxy --vnc localhost:5900
