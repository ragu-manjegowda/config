FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed git bash python mpv ffmpeg xorg-server-xvfb xdotool ttf-hack-nerd curl unzip
RUN curl --fail --location --retry 3 https://github.com/tomasklaen/uosc/releases/download/5.13.0/uosc.zip -o /tmp/uosc.zip \
    && unzip -q /tmp/uosc.zip -d /opt/uosc \
    && rm /tmp/uosc.zip

ENV MPV_GUI_UOSC=/opt/uosc/scripts/uosc
ENV GUI_ARTIFACTS=/artifacts
ENV PYTHONDONTWRITEBYTECODE=1
WORKDIR /workspace
CMD ["python3", "-B", ".config/mpv/tests/gui_mpv.py"]
