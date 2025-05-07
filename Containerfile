FROM fedora:42

RUN dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm && \
  dnf install -y git which && \
  dnf builddep -y mesa

COPY ./mesa-git /opt/mesa/mesa-git/
COPY ./entry.sh /opt/mesa/
WORKDIR /opt/mesa

ENTRYPOINT [ "/opt/mesa/entry.sh" ]
