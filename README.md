# dystopia-server
Dystopia game server dockerized

Docker Hub: [atomy/dystopia-server](https://hub.docker.com/r/atomy/dystopia-server)

# Run
`docker-compose up -d`

## Logs
`docker-compose logs -f`

## Metamod / Sourcemod
Place the addons/ folder in the folder where `docker-compose.yml` is.
Add to `docker-compose.yml` in the volumes-section:
`      - ./addons:/home/steamsrv/dystopia/dystopia/addons`

(optional)
Fix permissions for sourcemod to write logs (host):
`chmod -R 777 addons/sourcemod/logs/`

# Rebuild container (optional)
If you need to change anything in Dockerfile, you need to rebuild container: `docker build -t atomy/dystopia-server .`
