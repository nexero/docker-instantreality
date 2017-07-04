#!/bin/bash
PA_NETWORK_PREVIOUS=$(gconftool-2 -g /system/pulseaudio/modules/remote-access/enabled)
gconftool-2 -t bool -s /system/pulseaudio/modules/remote-access/enabled true
pulseaudio -k && pulseaudio --start

cat /etc/passwd > /tmp/passwd
echo $(getent passwd $(whoami)) >> /tmp/passwd

cat /etc/group > /tmp/group
echo $(getent group $(id -g $(whoami))) >> /tmp/group

if hash nvidia-docker 2>/dev/null; then
  DOCKER_BINARY='nvidia-docker'
else
  DOCKER_BINARY='docker'
fi

OPTIONS=(
         "$DOCKER_BINARY"
         'run'
         '--rm'
         #'-it'
         '-v /tmp/.X11-unix:/tmp/.X11-unix'
         '-e DISPLAY'
         '--device=/dev/dri:/dev/dri'
         '--device=/dev/snd'
         "-e PULSE_SERVER=tcp:$(ip -f inet addr show docker0 | grep -Po 'inet \K[\d.]+'):4713"
         "-v $HOME:$HOME"
         "-u=$(id -u $(whoami)):$(id -g $(whoami))"
         '-v /tmp:/tmp'
         '-v /tmp/passwd:/etc/passwd'
         '-v /tmp/group:/etc/group'
         '-v /usr/share/themes:/usr/share/themes'
         '-v /usr/share/gtk-engines:/usr/share/gtk-engines'
         '-v /usr/share/icons:/usr/share/icons'
        )


if [ -d /usr/lib/x86_64-linux-gnu/gtk-2.0 ]; then
  OPTIONS+=('-v /usr/lib/x86_64-linux-gnu/gtk-2.0:/usr/lib/x86_64-linux-gnu/gtk-2.0')
  OPTIONS+=('-v /usr/lib/x86_64-linux-gnu/gtk-3.0:/usr/lib/x86_64-linux-gnu/gtk-3.0')
elif [ -d /usr/lib/gtk-2.0 ]; then
  OPTIONS+=('-v /usr/lib/gtk-2.0:/usr/lib/x86_64-linux-gnu/gtk-2.0')
  OPTIONS+=('-v /usr/lib/gtk-3.0:/usr/lib/x86_64-linux-gnu/gtk-3.0')
fi

if [ -d /vol ]; then
  OPTIONS+=('-v /vol:/vol')
fi

if hash nvidia-docker 2>/dev/null; then
  OPTIONS+=('nexero/instantplayer:trusty-nvidia')
else
  OPTIONS+=('nexero/instantplayer:trusty-intel')
fi

dbus-launch sudo ${OPTIONS[@]}

gconftool-2 -t bool -s /system/pulseaudio/modules/remote-access/enabled $PA_NETWORK_PREVIOUS

rm /tmp/{passwd,group}
