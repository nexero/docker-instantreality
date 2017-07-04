FROM library/ubuntu:14.04

LABEL com.nvidia.volumes.needed="nvidia_driver"

RUN echo "deb http://archive.ubuntu.com/ubuntu/ trusty multiverse" >> /etc/apt/sources.list;\
    echo "deb http://archive.ubuntu.com/ubuntu/ trusty-updates multiverse" >> /etc/apt/sources.list

RUN apt-get update;\
    apt-get install -y --no-install-recommends curl;\
    curl http://doc.instantreality.org/media/uploads/downloads/2.8.0/InstantReality-Ubuntu-14.04-x64-2.8.0.38619.deb > /tmp/InstantReality-Ubuntu-14.04-x64-2.8.0.38619.deb;\
    apt-get purge -y curl;\ 
    apt-get autoremove -y;\
    dpkg -i /tmp/InstantReality-Ubuntu-14.04-x64-2.8.0.38619.deb;\
    apt-get install -y -f --no-install-recommends;\
    apt-get install --no-install-recommends -y libasound2-plugins libopenal1 zenity;\
    rm -f /tmp/InstantReality-Ubuntu-14.04-x64-2.8.0.38619.deb;\
    apt-get autoclean -y;\
    rm -rf /var/lib/apt/lists/*

RUN echo "drivers=pulse" >> /etc/openal/alsoft.conf

RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
ENV QT_X11_NO_MITSHM 1

ENTRYPOINT zenity --info \
                  --title="InstantPlayer Webinterface URL" \
                  --text="http://$(ip -f inet addr show eth0 | grep -Po 'inet \K[\d.]+'):35668" & \
           /usr/local/bin/InstantPlayer

