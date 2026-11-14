FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed base-devel git lua cairo pango gdk-pixbuf2 \
    xcb-util-cursor xcb-util-keysyms xcb-util-wm xcb-util-xrm libxdg-basedir libxkbcommon-x11 \
    startup-notification xorg-server-xvfb dbus imagemagick ttf-hack-nerd upower playerctl \
    libcanberra gtk3 python xdotool
RUN useradd -m -s /bin/bash builder \
    && printf 'builder ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/gui-builder \
    && chmod 440 /etc/sudoers.d/gui-builder
RUN cd /tmp \
    && runuser -u builder -- git clone https://aur.archlinux.org/lua-lgi-git.git \
    && runuser -u builder -- bash -c 'cd /tmp/lua-lgi-git && makepkg -si --noconfirm' \
    && runuser -u builder -- git clone https://aur.archlinux.org/awesome-git.git \
    && runuser -u builder -- bash -c 'cd /tmp/awesome-git && MAKEFLAGS="-j2" makepkg -si --noconfirm'

ENV GUI_ARTIFACTS=/artifacts
ENV PYTHONDONTWRITEBYTECODE=1
WORKDIR /workspace
CMD ["python3", "-B", ".config/awesome/tests/gui_centers.py"]
