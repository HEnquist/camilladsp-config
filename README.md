# Configuring and running CamillaDSP

## Running as a systemd service under Fedora 31 and newer
This is a way to run CamillaDSP as a systemd service to provide system wide filtering. This uses the Alsa backend for both capture and playback. These steps work on Fedora 31 and newer. Other distributions are probably similar, but there are likely some differences. If you try on another distribution and have to do something differently, please let me know and I will add that here.

### Step 1: Install CamillaDSP to /usr/local/bin
- Clone the repo and install with ```sudo cargo install --path . --root /usr/local/```

### Step 2: Load loopback driver on boot
- Copy ```aloop.conf``` to ```/etc/modules-load.d/aloop.conf```
- Reboot or load it manually with ```sudo modprobe snd-aloop```
- This creates a loopback device, so sound sent to "hw:Loopback,0" can be captured from "hw:Loopback,1".


### Step 3: Add an Alsa "plug" for sample format conversion etc
This creates a "plug" device named "camilladsp" that sends its output to the Loopback device.
- Copy ```asound.conf``` to ```/etc/asound.conf```


### Step 4: Create the CamillaDSP configuration
- Use Alsa for both playback and capture, see ```alsaconfig.yml``` for an example.
- Use "hw:Loopback,1" for capture device.
- Set the capture sample format and rate to the same as for the plug device
- Set the playback device to your dac, and the best sample format it supports.


### Step 4: Set up systemd service for CamillaDSP
- Edit as needed and copy ```camilladsp.service``` to ```/etc/systemd/system/camilladsp.service```.
- Reload the config: ```sudo systemctl daemon-reload```
- Start the service: ```sudo systemctl start camilladsp```
- Check the service status: ```sudo systemctl status camilladsp```
- If all ok, enable the service so it runs automatically: ```sudo systemctl enable camilladsp```


### Step 5 (Optional,for usb dac) Add udev rule to start service when dac is connected
- Figure out the vendor id of the dac using udevadm. Run ```udevadm monitor --subsystem-match=usb --property --udev``` and plug in the dac. There should be a few pages of output (see udevadm_output.txt for an example). 
- Look for the vendor id of the dac. In the example it's "20b1".
- Edit ```90-camilladsp.rules``` and replace the id with the one for your dac.
- Copy the file to ```/etc/udev/rules.d/90-camilladsp.rules```
- Reload the udev config: ```sudo udevadm control --reload-rules```
- Unplug the dac, wait a few seconds and plug it back in. Then check that the service started: ```sudo systemctl status camilladsp```


### Step 6 (optional) Send desktop audio to CamillaDSP
Follow either the PulseAudio or the Pipewire steps.

To check what your system uses, run `pactl info` in a terminal and look at the line starting with "Server Name":
```
> pactl info
...
Server Name: PulseAudio (on PipeWire 0.3.30)
...
```
In this example Pipewire is used. 

#### PulseAudio
- Open ```/etc/pulse/default.pa``` in a text editor (see ```default.pa``` for an example).
- Add these two lines (lines 43-44 in example):
    ```
    load-module module-alsa-sink device="camilladsp" sink_name="CamillaDSP"
    update-sink-proplist CamillaDSP device.description=CamillaDSP
    ```
- Comment out the autodetection module (lines 47-54 in example). This stops PulseAudio from finding and trying to use the Loopback and dac directly.
- Set camilladsp as the default sink (line 152): ```set-default-sink camilladsp```
- Save the file.

#### Pipewire
- Open ```~/.config/pipewire/pipewire.conf``` in a text editor. If the file doesn't exist, create it by copying the template from: ```/usr/share/pipewire/pipewire.conf```
- Under `context.properties`, set the desired sample rate:
    ```
        default.clock.rate        = 44100
    ```

- Add this block under `context.objects`:

    ```
        {   factory = adapter
            args = {
                factory.name            = api.alsa.pcm.sink
                node.name               = "alsa-sink"
                node.description        = "Alsa Loopback"
                media.class             = "Audio/Sink"
                api.alsa.path           = "hw:Loopback,1,0"
                #api.alsa.period-size   = 1024
                #api.alsa.headroom      = 0
                #api.alsa.disable-mmap  = false
                #api.alsa.disable-batch = false
                audio.format           = "S32LE"
                audio.rate             = 44100
                audio.channels         = 2
                #audio.position         = "FL,FR"
            }
        }
    ```
- Set `api.alsa.path` to the name of the loopback to output to.
- Set `audio.rate` to match the rate set above.
- If unsure, compare with the `pipewire.conf` in this repository.
- Save the file.
- After reboot, the audio settings should show a new output device called "Alsa Loopback".

### Step 7: Reboot to verify that everything starts ok



