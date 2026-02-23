FROM steamcmd/steamcmd:latest

RUN useradd -m -d /home/steamsrv -s /bin/bash steamsrv \
    && mkdir -p /home/steamsrv \
    && chown -R steamsrv:steamsrv /home/steamsrv

# switch to user steamsrv
USER steamsrv
WORKDIR /home/steamsrv
ENV HOME=/home/steamsrv

RUN /usr/bin/steamcmd +force_install_dir /home/steamsrv/dystopia +login anonymous +app_update 17585 +exit || true \
    && chmod -R u+w /home/steamsrv/dystopia

COPY --chown=steamsrv:steamsrv dystopia-asm-fixes/server_srv.so /home/steamsrv/dystopia/bin/linux32/server_srv.so

ENV LD_LIBRARY_PATH=/home/steamsrv/dystopia/bin/linux32:$LD_LIBRARY_PATH

WORKDIR /home/steamsrv/dystopia/bin/linux32

EXPOSE 27015
EXPOSE 27015/udp

ENTRYPOINT []
CMD ["./srcds", "-game", "/home/steamsrv/dystopia/dystopia", "+log", "on", "-maxplayers", "32", "-ip", "0.0.0.0", "-port", "27015", "+map", "dys_vaccine"]
