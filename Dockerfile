FROM gameservers/steamcmd

ADD server.cfg /tmp/server.cfg

RUN steamcmd/steamcmd.sh +force_install_dir /home/steamsrv/dystopia +login anonymous +app_update 17585 +exit || true

EXPOSE 27015
EXPOSE 27015/udp

USER steamsrv

ENV LD_LIBRARY_PATH=/home/steamsrv/dystopia/bin/linux32:$LD_LIBRARY_PATH

WORKDIR /home/steamsrv/dystopia/bin/linux32

CMD ["./srcds", "-game", "/home/steamsrv/dystopia/dystopia", "+log", "on", "-maxplayers", "32", "-ip", "0.0.0.0", "-port", "27015", "+map", "dys_vaccine"]
