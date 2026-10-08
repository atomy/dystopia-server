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

## AI bots (dysbot, optional)
The dysbot plugin is not part of this repo or the image. You provide the files on the host and they get bind-mounted at run time.
Without the override below nothing changes.

### Host layout
One folder next to `docker-compose.yml`, default `./dysbot-dist` (override with `DYSBOT_DIR`):
```
dysbot-dist/
  dysbot.vdf
  dysbot/
    bin/dysbot.so                <- 32-bit build
    maps/  nav/  cfg/ (optional)
    dysbot.cfg  loadouts.txt  weapons.txt  chat.txt  voicecomms.txt
    logs/  recordings/           <- must be writable by the container user
```
Do not copy `dysbot_x64.vdf`, `bin/x64/`, `*.dll` or `*.pdb`. The server is 32-bit and would log a "wrong ELF class" error for the x64 plugin.

### Copy the files
From a Windows install (Git Bash):
```bash
src=/m/SteamLibrary/steamapps/common/Dystopia/dystopia/addons
dst=./dysbot-dist
mkdir -p "$dst/dysbot/bin" "$dst/dysbot/logs" "$dst/dysbot/recordings"
cp "$src/dysbot.vdf" "$dst/"
cp "$src/dysbot/bin/dysbot.so" "$dst/dysbot/bin/"
cp -r "$src/dysbot/maps" "$src/dysbot/nav" "$dst/dysbot/"
[ -d "$src/dysbot/cfg" ] && cp -r "$src/dysbot/cfg" "$dst/dysbot/"
cp "$src/dysbot/"{dysbot.cfg,loadouts.txt,weapons.txt,chat.txt,voicecomms.txt} "$dst/dysbot/"
```
Then make `logs/` and `recordings/` writable by the container user (`steamsrv`). Check its uid with `docker compose run --rm dys-server id`, then on the host:
`chown -R 1000:1000 dysbot-dist/dysbot/logs dysbot-dist/dysbot/recordings`
(or `chmod 777` on both if the uid differs).

### Enable
Needs Docker Compose v2 (`docker compose`). Either pass the override explicitly:
`docker compose -f docker-compose.yml -f docker-compose.dysbot.yml up -d`

or copy `.env.example` to `.env` and uncomment `COMPOSE_FILE`, then plain `docker compose up -d` includes it.
The override only adds the two dysbot mounts; `server.cfg` stays mounted.

### Verify
1. `docker compose logs dys-server | grep -i dysbot` shows the plugin load line and no "Unable to load plugin".
2. Server console (`docker attach`, or rcon): `plugin_print` lists dysbot.
3. `dysbot_quota 4` adds 4 bots on balanced teams.
4. Files show up in `dysbot-dist/dysbot/logs/` on the host.

### Settings
Put these in `server.cfg` or `dysbot/dysbot.cfg`:
- `dysbot_quota N`: keep N bots on balanced teams (default 0, one slot stays free for humans)
- `dysbot_add [punk|corp|auto] [light|medium|heavy|auto]`: add a single bot
- `dysbot_kick all`: remove all bots
- `dysbot_defender_handicap 0.3`: temporary defender weakening (default)
- `dysbot_rec_auto 1`: pub-mode recording of human players, including SteamIDs (off by default)

Bots only have map data for the official maps: dys_assemble, broadcast, cybernetic, detonate, exodus, fortress, fusion, injection, silo, undermine and vaccine.

### Pitfalls
- **Missing files:** `up` fails with a "bind source path does not exist" error. That is intended: the short volume syntax would silently create empty directories instead and the plugin wouldn't load.
- **Already mounting `./addons` (Metamod/Sourcemod):** the override still works on top of it, but Docker creates empty placeholder `dysbot.vdf`/`dysbot` entries in your host `./addons`. Alternatively, put `dysbot.vdf` and `dysbot/` directly into your host `./addons` and skip the override.
- **32-bit only:** `bin/dysbot.so` must be the 32-bit build. There is no 64-bit Dystopia server.
- **Writable dirs:** if `logs/` or `recordings/` are not writable, the plugin still runs but its log and recordings are lost.
- **Updating the plugin:** replace the files on the host, then `docker compose restart dys-server`. Don't overwrite `dysbot.so` in place while the server runs (the process has it mapped): copy to a temp name and rename, or stop the server first. Map JSON and nav files are re-read at each map load.
- **VAC:** the plugin loads on VAC-secure servers, no `-insecure` needed.
- **Game version:** dysbot is built against the public branch (1.5.8.92), which is what the image installs.

# Rebuild container (optional)
If you need to change anything in Dockerfile, you need to rebuild container: `docker build -t atomy/dystopia-server .`
