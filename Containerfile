FROM fedora:43

RUN dnf install -y \
  # install RPMFusion
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm && \
  # install build deps for mesa
  dnf install -y git which && \
  dnf builddep -y mesa

COPY ./entry.sh /opt/mesa/
COPY ./mesa-git/ /opt/mesa/mesa-git/
WORKDIR /opt/mesa

ENTRYPOINT [ "/opt/mesa/entry.sh" ]
