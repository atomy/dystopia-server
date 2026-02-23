FROM steamcmd/steamcmd:latest

RUN useradd -m -d /home/steamsrv -s /bin/bash steamsrv
RUN mkdir -p /home/steamsrv
RUN chown -R steamsrv:steamsrv /home/steamsrv

# switch to user steamsrv
USER steamsrv
WORKDIR /home/steamsrv
ENV HOME=/home/steamsrv

RUN /usr/bin/steamcmd +force_install_dir /home/steamsrv/dystopia +login anonymous +app_update 17585 +exit || true && \
    test -d /home/steamsrv/dystopia/dystopia || { echo "ERROR: Steam install failed - /home/steamsrv/dystopia/dystopia not found"; exit 1; }

USER root

# Enable the 'universe' repository and add 32-bit architecture support
RUN apt-get update && apt-get install -y wget

# Manually download and install 32-bit libtinfo5 and libncurses5
RUN wget http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.2-0ubuntu2_i386.deb && \
    wget http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.2-0ubuntu2_i386.deb && \
    dpkg -i libtinfo5_6.2-0ubuntu2_i386.deb libncurses5_6.2-0ubuntu2_i386.deb && \
    rm libtinfo5_6.2-0ubuntu2_i386.deb libncurses5_6.2-0ubuntu2_i386.deb

# Verify the installation
RUN ldconfig -p | grep -E "libtinfo.so.5|libncurses.so.5"

COPY dystopia-asm-fixes/server_srv.so /home/steamsrv/dystopia/bin/linux32/server_srv.so

USER steamsrv
ENV LD_LIBRARY_PATH=/home/steamsrv/dystopia/bin/linux32:$LD_LIBRARY_PATH

RUN mkdir -p /home/steamsrv/.steam/sdk32/
RUN ln -s /home/steamsrv/dystopia/bin/linux32/steamclient.so /home/steamsrv/.steam/sdk32/steamclient.so

WORKDIR /home/steamsrv/dystopia/bin/linux32

EXPOSE 27015
EXPOSE 27015/udp

ENTRYPOINT []
CMD ["./srcds", "-game", "/home/steamsrv/dystopia/dystopia", "+log", "on", "-maxplayers", "32", "-ip", "0.0.0.0", "-port", "27015", "+map", "dys_vaccine"]
