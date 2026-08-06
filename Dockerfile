FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8
ENV GTK_IM_MODULE=ibus
ENV QT_IM_MODULE=ibus
ENV XMODIFIERS=@im=ibus

RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    init \
    systemd \
    snapd \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    locales \
    language-pack-zh-hans \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    ibus \
    ibus-libpinyin \
    im-config \
    openssl

RUN apt update -y && apt install -y \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps

# 保持单独安装，不要放到 --no-install-recommends 的命令中
RUN apt install software-properties-common -y

# 安装 Firefox PPA
RUN add-apt-repository ppa:mozillateam/ppa -y

RUN echo 'Package: *' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:jammy";' \
    | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox

RUN apt update -y && apt install -y firefox
RUN apt update -y && apt install -y xubuntu-icon-theme

# 生成中文 UTF-8 locale，解决中文乱码
RUN locale-gen zh_CN.UTF-8 && update-locale LANG=zh_CN.UTF-8

RUN touch /root/.Xauthority
RUN mkdir -p /root/.vnc

# VNC 中启动 XFCE、DBus 和 IBus 拼音
RUN printf '%s\n' \
    '#!/bin/sh' \
    'unset SESSION_MANAGER' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'export LANG=zh_CN.UTF-8' \
    'export LANGUAGE=zh_CN:zh' \
    'export LC_ALL=zh_CN.UTF-8' \
    'export GTK_IM_MODULE=ibus' \
    'export QT_IM_MODULE=ibus' \
    'export XMODIFIERS=@im=ibus' \
    'eval "$(dbus-launch --sh-syntax)"' \
    'ibus-daemon -drx' \
    'ibus engine libpinyin' \
    'exec startxfce4' \
    > /root/.vnc/xstartup \
    && chmod +x /root/.vnc/xstartup

EXPOSE 5901
EXPOSE 6080

CMD bash -c 'vncserver -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && openssl req -new -subj "/C=JP" -x509 -days 365 -nodes -out /root/self.pem -keyout /root/self.pem && websockify --web=/usr/share/novnc/ --cert=/root/self.pem 6080 localhost:5901'
