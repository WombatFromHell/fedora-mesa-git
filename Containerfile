FROM fedora:42

RUN dnf install -y \
  # install RPMFusion
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm && \
  #
  # install extra codecs
  # dnf group install -y multimedia --setopt=install_weak_deps=False --exclude=PackageKit-gstreamer-plugin && \
  # dnf swap -y ffmpeg-free ffmpeg --allowerasing && \
  # dnf swap -y mesa-va-drivers mesa-va-drivers-freeworld && \
  # dnf swap -y mesa-vdpau-drivers mesa-vdpau-drivers-freeworld && \
  # dnf swap -y mesa-va-drivers.i686 mesa-va-drivers-freeworld.i686 && \
  # dnf swap -y mesa-vdpau-drivers.i686 mesa-vdpau-drivers-freeworld.i686 && \
  #
  # install build deps for mesa
  dnf install -y git which && \
  dnf builddep -y mesa

COPY ./entry.sh /opt/mesa/
COPY ./mesa-git/ /opt/mesa/mesa-git/
WORKDIR /opt/mesa

ENTRYPOINT [ "/opt/mesa/entry.sh" ]
