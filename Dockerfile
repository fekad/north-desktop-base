FROM quay.io/jupyter/base-notebook:latest

# Fix: https://github.com/hadolint/hadolint/wiki/DL4006
# Fix: https://github.com/koalaman/shellcheck/wiki/SC3014
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

RUN apt-get -y -qq update \
 && apt-get -y -qq install \
        dbus-x11 \
        # xclip is added as jupyter-remote-desktop-proxy's tests requires it
        openbox \
        obconf \
        xorg \
        xubuntu-icon-theme \
        fonts-dejavu \
    # chown $HOME to workaround that the xorg installation creates a
    # /home/jovyan/.cache directory owned by root
    #  && chown -R $NB_UID:$NB_GID $HOME \
 && fix-permissions "/home/${NB_USER}" \
 && rm -rf /var/lib/apt/lists/*

# Install a VNC server (TurboVNC)
# Install instructions from https://turbovnc.org/Downloads/YUM
ENV PATH=/opt/TurboVNC/bin:$PATH
RUN wget -q -O- https://packagecloud.io/dcommander/turbovnc/gpgkey | \
    gpg --dearmor >/etc/apt/trusted.gpg.d/TurboVNC.gpg \
 && wget -O /etc/apt/sources.list.d/TurboVNC.list https://raw.githubusercontent.com/TurboVNC/repo/main/TurboVNC.list \
 && apt-get -y -qq update \
 && apt-get -y -qq install \
        turbovnc \
 && rm -rf /var/lib/apt/lists/*

USER $NB_USER

RUN mamba install --yes \
    'jupyter-server-proxy' \
    'jupyterhub-singleuser' \
 && fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"

RUN pip install --no-cache-dir jupyter-remote-desktop-proxy

# Switch back to jovyan to avoid accidental container runs as root
USER ${NB_UID}
WORKDIR "${HOME}"