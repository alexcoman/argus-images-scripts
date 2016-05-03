IMAGE="windows-image.qcow2"
FLOPPY="Autounattend.vfd"
VIRTIO_ISO="virtio-win.iso"
ISO="dvd.ISO"

echo "creating FLOPPY"

KVM=/usr/libexec/qemu-kvm
if [ ! -f "$KVM" ]; then
    KVM=/usr/bin/kvm
fi
echo "creating disk!"
qemu-img create -f qcow2 -o preallocation=metadata $IMAGE 17G
echo "installing windows on disk!"
$KVM -m 2048 -smp 2 -cdrom $ISO -drive file=$VIRTIO_ISO,index=3,media=cdrom,boot=on -fda $FLOPPY $IMAGE -boot d -vga std -k en-us -vnc :3
