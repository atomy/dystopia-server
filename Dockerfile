FROM steamcmd/steamcmd:ubuntu-22

# 32-bit srcds. Do not use Ubuntu 24+ (steamcmd:latest): i386 time_t is 64-bit there
# and ncurses5 is gone, which segfaults at startup. See https://dystopia-game.com/serverguide.php
ARG DEBIAN_FRONTEND=noninteractive
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      libc6:i386 \
      libstdc++6:i386 \
      lib32gcc-s1 \
      libcurl3-gnutls:i386 \
      libncurses5:i386 \
      libtinfo5:i386 \
      libsdl2-2.0-0:i386 \
      ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/steamsrv -s /bin/bash steamsrv \
 && chown -R steamsrv:steamsrv /home/steamsrv

USER steamsrv
WORKDIR /home/steamsrv
ENV HOME=/home/steamsrv

RUN /usr/bin/steamcmd +force_install_dir /home/steamsrv/dystopia +login anonymous +app_update 17585 validate +quit || true \
 && test -d /home/steamsrv/dystopia/dystopia || { echo "ERROR: Steam install failed - /home/steamsrv/dystopia/dystopia not found"; exit 1; } \
 && test -x /home/steamsrv/dystopia/srcds_run || { echo "ERROR: srcds_run missing after Steam install"; exit 1; }

USER root
# Fail the build if a system library is still missing (same check as the server guide)
RUN missing="$(LD_LIBRARY_PATH=/home/steamsrv/dystopia/bin/linux32:/home/steamsrv/dystopia/bin \
      ldd /home/steamsrv/dystopia/bin/linux32/*_srv.so 2>/dev/null | grep -i 'not found' || true)" \
 && if [ -n "$missing" ]; then echo "ERROR: missing 32-bit libraries:" >&2; echo "$missing" >&2; exit 1; fi

USER steamsrv
ENV LD_LIBRARY_PATH=/home/steamsrv/dystopia/bin/linux32:/home/steamsrv/dystopia/bin

RUN mkdir -p /home/steamsrv/.steam/sdk32 \
 && ln -s /home/steamsrv/dystopia/bin/linux32/steamclient.so /home/steamsrv/.steam/sdk32/steamclient.so

WORKDIR /home/steamsrv/dystopia

EXPOSE 27015
EXPOSE 27015/udp

ENTRYPOINT []
CMD ["./srcds_run", "-game", "dystopia", "-console", "-port", "27015", "+maxplayers", "32", "-ip", "0.0.0.0", "+map", "dys_vaccine", "+exec", "server.cfg", "+log", "on"]
