#!/bin/sh
sudo modprobe -v v4l2loopback exclusive_caps=1 card_label="Virtual Webcam"
scrcpy --video-source=camera --no-audio --camera-id=0 --camera-size=1920x1080 --v4l2-sink=/dev/video0
sudo modprobe -v -r v4l2loopback

# https://adityatelange.in/blog/android-phone-webcam-linux/
