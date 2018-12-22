# AnyKernel2 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=Despair Kernel
do.devicecheck=0
do.modules=0
do.cleanup=1
do.cleanuponabort=0
device.name1=maguro
device.name2=toro
device.name3=toroplus
device.name4=
device.name5=
'; } # end properties

# shell variables
block=/dev/block/bootdevice/by-name/boot;
is_slot_device=1;
ramdisk_compression=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. /tmp/anykernel/tools/ak2-core.sh;


## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
chmod -R 750 $ramdisk/*;
chmod -R 755 $ramdisk/sbin;
chown -R root:root $ramdisk/*;


## AnyKernel install
dump_boot;

# If the kernel image and dtbs are separated in the zip
decompressed_image=/tmp/anykernel/kernel/Image
compressed_image=$decompressed_image.lz4
if [ -f $compressed_image ]; then
  # Hexpatch the kernel if Magisk is installed ('skip_initramfs' -> 'want_initramfs')
  if [ -d $ramdisk/.backup ]; then
    ui_print " "; ui_print "Magisk detected! Patching kernel so reflashing Magisk is not necessary...";
    $bin/magiskboot --decompress $compressed_image $decompressed_image;
    $bin/magiskboot --hexpatch $decompressed_image 736B69705F696E697472616D667300 77616E745F696E697472616D667300;
    $bin/magiskboot --compress=lz4 $decompressed_image $compressed_image;
  fi;

  # Concatenate all of the dtbs to the kernel
  cat $compressed_image /tmp/anykernel/dtbs/*.dtb > /tmp/anykernel/Image.lz4-dtb;
fi;


# Patch dtbo.img on custom ROMs
username="$(file_getprop /system/build.prop "ro.build.user")";
echo "Found user: $username";
case "$username" in
  "android-build") user=google;;
  *) user=custom;;
esac;
hostname="$(file_getprop /system/build.prop "ro.build.host")";
echo "Found host: $hostname";
case "$hostname" in
  *corp.google.com|abfarm*) host=google;;
  *) host=custom;;
esac;
if [ "$user" == "custom" -o "$host" == "custom" ]; then
  if [ ! -z /tmp/anykernel/dtbo.img ]; then
    ui_print " "; ui_print "You are on a custom ROM, patching kernel to remove verity...";
    $bin/magiskboot --dtb-patch /tmp/anykernel/dtbo.img;
    $bin/magiskboot --dtb-patch /tmp/anykernel/Image.lz4-dtb;
    
  fi;
else
  ui_print " "; ui_print "You are on stock, not patching kernel to remove verity!";
fi;



# begin ramdisk changes

# end ramdisk changes

write_boot;

## end install

