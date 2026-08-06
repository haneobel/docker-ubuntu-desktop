FROM --platform=linux/amd64 ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=zh_CN.UTF-8
ENV LANGUAGE=zh_CN:zh
ENV LC_ALL=zh_CN.UTF-8
ENV GTK_IM_MODULE=ibus
ENV QT_IM_MODULE=ibus
ENV XMODIFIERS=@im=ibus
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    software-properties-common \
    locales \
    language-pack-zh-hans \
    fonts-noto-cjk \
    fonts-noto-cjk-extra \
    ibus \
    ibus-libpinyin \
    im-config \
    xubuntu-icon-theme \
    openssl \
    && locale-gen zh_CN.UTF-8 \
    && update-locale LANG=zh_CN.UTF-8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# Firefox Mozilla Team PPA
RUN add-apt-repository ppa:mozillateam/ppa -y \
    && echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox \
    && echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox \
    && echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox \
    && apt-get update \
    && apt-get install -y firefox \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
RUN touch /root/.Xauthority \
    && mkdir -p /root/.vnc
# VNC 启动 XFCE、DBus 和 IBus 拼音
RUN cat > /root/.vnc/xstartup <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_ALL=zh_CN.UTF-8
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
eval "$(dbus-launch --sh-syntax)"
# 启动 IBus，并启用 libpinyin 输入法引擎
ibus-daemon -drx
exec startxfce4
EOF
RUN chmod +x /root/.vnc/xstartup
RUN cat > /usr/local/bin/start-vnc.sh <<'EOF'
#!/bin/bash
set -e

# 启动 VNC :1，对应 5901 端口
vncserver :1 \
  -localhost no \
  -SecurityTypes None \
  -geometry 1024x768 \
  --I-KNOW-THIS-IS-INSECURE
# noVNC HTTPS 证书
if [ ! -f /root/self.pem ]; then
  openssl req -new -x509 -days 365 -nodes \
    -subj "/C=JP" \
    -out /root/self.pem \
    -keyout /root/self.pem
fi
# noVNC: 6080 -> VNC 5901
websockify \
  --web=/usr/share/novnc/ \
  --cert=/root/self.pem \
  6080 localhost:5901
EOF
RUN chmod +x /usr/local/bin/start-vnc.sh
EXPOSE 5901 6080
CMD ["/usr/local/bin/start-vnc.sh"]
