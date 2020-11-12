#!/bin/sh

# Script to simple and versatil create an USB MIDI gadget
# Based on info at 
# * https://www.kernel.org/doc/html/v5.3/usb/gadget_configfs.html
# * https://wiki.tizen.org/USB/Linux_USB_Layers/Configfs_Composite_Gadget/Usage_eq._to_g_midi.ko 
# * https://www.hardill.me.uk/wordpress/2019/11/02/pi4-usb-c-gadget/
# * https://github.com/torvalds/linux/blob/6f0d349d922ba44e4348a17a78ea51b7135965b1/drivers/usb/gadget/function/f_midi.c


# Check default values at begining of this file and modify them at /etc/default/midiconfigfs
# or via arguments ($0 --help)
# also there you can call default enable_udc_raspberrypi4 or enable_udc_orangepi_zero or
# enable UDC yourself

set -e 

CONFIGFS=/sys/kernel/config
NAME="USB Gadget"
MANUFACTURER="Unknown"
SAFE_NAME=$( echo $NAME | sed 's/[-. ]/_/g' )
ID_VENDOR=0x0000
ID_PRODUCT=0x0000
IN_PORTS=1
OUT_PORTS=1
SERIAL=0
UDC=$( ls -1 /sys/class/udc | head -1 )

# can modify at /etc/default/midiconfigfs
pre_enable(){
    true
}

# can modify at /etc/default/midiconfigfs
post_enable(){
    true
}

enable_udc_raspberrypi4(){
    echo "Ensure UDC is enabled for Raspberry PI 4"
    modprobe libcomposite
    cat /boot/overlays/dwc2.dtbo > /sys/kernel/config/device-tree/overlays/dwc2/dtbo
    modprobe dwc2
    UDC=$( ls -1 /sys/class/udc | head -1 )
}

enable_udc_orangepi_zero(){
    echo "Ensure UDC is enabled for Orange Pi Zero"
    rmmod g_serial
    modprobe libcomposite
    UDC=$( ls -1 /sys/class/udc | head -1 )
}
    
[ -e "/etc/default/midiconfigfs" ] && . /etc/default/midiconfigfs

parse_arguments() {
    while [ "$1" ]; do
        case $1 in
        -h|--help)
            help
            ;;
        --name)
            shift
            NAME=$1
            ;;
        --usb_id|--usb-id)
            shift
            ID_PRODUCT=$( echo $1 | sed s/.*://g | sed s/^0x//g )
            ID_VENDOR=$( echo $1 | sed s/:.*//g | sed s/^0x//g )
            ;;
        --raspberrypi4)
            enable_udc_orangepi_zero
            ;;
        --orangepizero)
            enable_udc_orangepi_zero
            ;;
        --remove)
            remove_configfs_midi
            exit 0
            ;;
        --recreate)
            remove_configfs_midi || true
            create_configfs_midi
            exit 0
            ;;
        --in_ports|--in-ports)
            shift
            IN_PORTS=$1
            ;;
        --out_ports|--out-ports)
            shift
            OUT_PORTS=$1
            ;;
        *)
            echo "Unknown argument $1"
            exit 1
            ;;
        esac
        shift
    done
}

help() {
    cat << EOF
$0 - Simple wrapper to create a MIDI gadget

Arguments:  
 --name NAME          -- Set product name. Also used to remove it later.
 --manufacturer NAME  -- Set manufacturer name. Also used to remove it later.
 --usb-id             -- Set the id_vendor:id_product
 --remove NAME        -- Removes the USB Gadget
 --recreate NAME      -- Removes (if it exists) and creates it again
 --in-ports NN        -- Creates NN in ports. Default 1.
 --out-ports NN        -- Creates NN in ports. Default 1.

 --raspberrypi4       -- Ensure UDC works for Raspberry Pi 4
 --orangepizero       -- Ensure UDC works for Orange Pi Zero
EOF
}

create_configfs_midi() {
    # If already loaded, does nothing.
    modprobe libcomposite

    echo "Creating $NAME with USB id $ID_VENDOR:$ID_PRODUCT at $CONFIGFS/usb_gadget/$SAFE_NAME"
    UDC_USER=$( cat /sys/class/udc/$UDC/function )
    if [ "$UDC_USER" ]; then
        echo "UDC is currently in use by $UDC_USER. Aborting."
        exit 1
    fi

    cd $CONFIGFS/usb_gadget
    mkdir "$SAFE_NAME"
    cd "$SAFE_NAME"
    mkdir strings/0x409
    mkdir configs/c.1
    mkdir configs/c.1/strings/0x409
    mkdir functions/midi.$SAFE_NAME
    echo $ID_VENDOR > idVendor
    echo $ID_PRODUCT > idProduct
    echo $SERIAL > strings/0x409/serialnumber
    echo $NAME > strings/0x409/product
    echo $MANUFACTURER > strings/0x409/manufacturer
    echo $IN_PORTS > functions/midi.$SAFE_NAME/in_ports
    echo $OUT_PORTS > functions/midi.$SAFE_NAME/out_ports
    ln -s functions/midi.$SAFE_NAME configs/c.1
    # enable!
    pre_enable
    echo $UDC > UDC
    post_enable
}

remove_configfs_midi() {
    [ -e "$CONFIGFS/usb_gadget/$SAFE_NAME" ] || return
    echo "Removing USB gadget $NAME at $CONFIGFS/usb_gadget/$SAFE_NAME"
    cd $CONFIGFS/usb_gadget/$SAFE_NAME
    echo "" > UDC
    rmdir strings/0x409
    rmdir configs/c.1/strings/0x409
    rm configs/c.1/midi.$SAFE_NAME
    rmdir configs/c.1/  
    rmdir functions/midi.$SAFE_NAME
    cd ..
    rmdir $SAFE_NAME

}

main(){
    parse_arguments $*
    create_configfs_midi
}

main $*
