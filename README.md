# Configuring and running CamillDSP

## Running as a systemd service under Fedora 31
This is a way to run CamillaDSP as a systemd service to provide system wide filtering. This uses the Alsa backend for both capture and playback. These steps work on Fedora 31. Other distributions are probably similar, but there are probably some differences. If you try on another distribution and have to do something differently, please let me know and I will add that here.

### Step 1: Install CamillaDSP to /usr/local/bin
- Clone the repo and install with ```sudo cargo install --path . --root /usr/local/```

### Step 2: Load loopback driver on boot
- Copy ```aloop.conf``` to ```/etc/modules-load.d/aloop.conf```

### Step 3: Add an Alsa "plug" for sample format conversion etc
- Copy ```asound.conf``` to ```/etc/asound.conf```

### Step 4: Set up systemd service for CamillaDSP
- Edit as needed and copy ```camilladsp.service``` to ```/etc/systemd/system/camilladsp.service```.
- Reload the config: ```sudo systemctl daemon-reload```
- Start the service: ```sudo systemctl start camilladsp```
- Check the service status: ```sudo systemctl status camilladsp```
- If all ok, enable the service so it runs automatically: ```sudo systemctl enable camilladsp```


### Step 5 (Optional,fFor usb dac) Add udev rule to start service when dac is connected
- Figure out the vendor id of the dac using udevadm. Run ```udevadm monitor --subsystem-match=usb --property --udev``` and plug in the dac. There should be a few pages of output (see udevadm_output.txt for an example). 
- Look for the vendor id of the dac. In the example it's "20b1".
- Edit ```90-camilladsp.rules``` and replace the id with the one for your dac.
- Copy the file to ```/etc/udev/rules.d/90-camilladsp.rules```
- Reload the udev config: ```sudo udevadm control --reload-rules```
- Unplug the dac, wait a few seconds and plug it back in. Then check that the service started: ```sudo systemctl status camilladsp```

### Step 6 (optional) Send PulseAudio output to CamillaDSP (for desktop apps)
- Open ```/etc/pulse/default.pa``` in a text editor (see ```default.pa``` for an example).
- Add these two lines (lines 43-44 in example):
```
load-module module-alsa-sink device="camilladsp" sink_name="CamillaDSP"
update-sink-proplist CamillaDSP device.description=CamillaDSP
```
- Comment out the autodetection module (lines 47-54 in example). This stops PulseAudio from finding and trying to use the Loopback and dac directly.
- Set camilladsp as the default sink (line 152): ```set-default-sink camilladsp```
- Save the file.

### Step 7: Reboot to verify that everything starts ok



