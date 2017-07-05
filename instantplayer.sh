#!/bin/bash
### TODO: 
###  * sudoers

# enable pulse audio network remote-access 
if gconftool-2 -g /system/pulseaudio/modules/remote-access/enabled | grep "No value set"; then
  gconftool-2 -t bool -s /system/pulseaudio/modules/remote-access/enabled true
  pulseaudio -k && pulseaudio --start
  PA_NETWORK_PREVIOUS=false
else
  PA_NETWORK_PREVIOUS=$(gconftool-2 -g /system/pulseaudio/modules/remote-access/enabled)
fi
gconftool-2 -t bool -s /system/pulseaudio/modules/remote-access/enabled true

# create passwd and group lines for the container
cat /etc/passwd > /tmp/passwd
echo $(getent passwd $(whoami)) >> /tmp/passwd

cat /etc/group > /tmp/group
echo $(getent group $(id -g $(whoami))) >> /tmp/group

# check for nvidia graphics
if hash nvidia-docker 2>/dev/null; then
  DOCKER_BINARY='nvidia-docker'
else
  DOCKER_BINARY='docker'
fi

# define options as array
OPTIONS=(
         "$DOCKER_BINARY"
         'run'
         '--rm'
         '-it'
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

# parse additional args
if [ $# -gt 0 ]; then
  # if someone wants a bash prompt
  if [ "$1" = "/bin/bash" ]; then
    # coloring the prompt of the container
    OPTIONS+=('-e PS1=\[\033[41;37m\]docker_instantreality\[\033[0m\]:\w\$ ')
    OPTIONS+=('--entrypoint=/bin/bash')
    shift
    # for people with creative .bashrc, we add --norc 
    set -- "--norc" "$@"
#  elif [ "$1" = "sav" ]; then
#    OPTIONS+=('--entrypoint=/usr/local/bin/sav')
#    shift
  else
    OPTIONS+=('--entrypoint=/usr/local/bin/InstantPlayer')
  fi
fi

# for better desktop integration
if [ -d /usr/lib/x86_64-linux-gnu/gtk-2.0 ]; then
  OPTIONS+=('-v /usr/lib/x86_64-linux-gnu/gtk-2.0:/usr/lib/x86_64-linux-gnu/gtk-2.0')
  OPTIONS+=('-v /usr/lib/x86_64-linux-gnu/gtk-3.0:/usr/lib/x86_64-linux-gnu/gtk-3.0')
elif [ -d /usr/lib/gtk-2.0 ]; then
  OPTIONS+=('-v /usr/lib/gtk-2.0:/usr/lib/x86_64-linux-gnu/gtk-2.0')
  OPTIONS+=('-v /usr/lib/gtk-3.0:/usr/lib/x86_64-linux-gnu/gtk-3.0')
fi

# for /vol access
if [ -d /vol ]; then
  OPTIONS+=('-v /vol:/vol')
fi

# choose the image
if hash nvidia-docker 2>/dev/null; then
  IMAGE="4b3abae928f3"
  OPTIONS+=('nexero/instantplayer:trusty-nvidia')
else
  IMAGE="98f2e66a8b62"
  OPTIONS+=('nexero/instantplayer:trusty-intel')
fi

# load docker image from /vol/clfvr
if ! sudo docker images -q | grep $IMAGE; then
  cat /vol/clfvr/docker/instantplayer/$IMAGE.tar | sudo docker load
fi

# launch with dbus-launch, because otherwise there won't be a dbus-connection and the app may complain about that
dbus-launch sudo ${OPTIONS[@]} $@

# restore pulseaudio setting
gconftool-2 -t bool -s /system/pulseaudio/modules/remote-access/enabled $PA_NETWORK_PREVIOUS

# cleanup
rm /tmp/{passwd,group}
