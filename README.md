# dystopia-server
Dystopia game server dockerized

Docker Hub: [atomy/dystopia-server](https://hub.docker.com/r/atomy/dystopia-server)

# Run
`docker-compose up -d`

## Logs
`docker-compose logs -f`

## Updates
The game is baked into the image, so when Dystopia updates on Steam, run the "Build and Push Docker Image" workflow manually (Actions → Run workflow).
It pushes `latest` plus `build-<steam buildid>`. Then pull it on the host, otherwise clients get "server is running an older version of the game":
`docker-compose pull && docker-compose up -d`

Check which Steam build a running container has:
`docker inspect --format '{{ index .Config.Labels "dystopia.buildid" }}' <container>`

## Metamod / Sourcemod
Place the addons/ folder in the folder where `docker-compose.yml` is.
Add to `docker-compose.yml` in the volumes-section:
`      - ./addons:/home/steamsrv/dystopia/dystopia/addons`

(optional)
Fix permissions for sourcemod to write logs (host):
`chmod -R 777 addons/sourcemod/logs/`

# Rebuild container (optional)
If you need to change anything in Dockerfile, you need to rebuild container: `docker build -t atomy/dystopia-server .`
