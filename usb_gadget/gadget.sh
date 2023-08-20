#!/bin/sh

# USB Audio configuration:
AUDIO_CHANNEL_MASK=3
AUDIO_SAMPLE_RATES=44100
AUDIO_SAMPLE_SIZE=4

# Load libcomposite
modprobe libcomposite

# Create a gadget called usb-gadgets
cd /sys/kernel/config/usb_gadget/
mkdir -p usb-gadgets
cd usb-gadgets

# Configure our gadget details
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB2
mkdir -p strings/0x409
echo "0123456789abcdef" > strings/0x409/serialnumber
echo "CamillaDSP" > strings/0x409/manufacturer
echo "CamillaDSP" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409

# UAC2 (audio) gadget
# attributes from: https://www.kernel.org/doc/Documentation/ABI/testing/configfs-usb-gadget-uac2
mkdir -p functions/uac2.usb0
echo $AUDIO_CHANNEL_MASK > functions/uac2.usb0/c_chmask
echo $AUDIO_SAMPLE_RATES > functions/uac2.usb0/c_srate
echo $AUDIO_SAMPLE_SIZE > functions/uac2.usb0/c_ssize
echo $AUDIO_CHANNEL_MASK > functions/uac2.usb0/p_chmask
echo $AUDIO_SAMPLE_RATES > functions/uac2.usb0/p_srate
echo $AUDIO_SAMPLE_SIZE > functions/uac2.usb0/p_ssize
echo "CamillaDSP gadget" > functions/uac2.usb0/function_name
ln -s functions/uac2.usb0 configs/c.1/

# End functions
ls /sys/class/udc > UDC
