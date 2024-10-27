# Hollow Knight Multiworld (HKMW) / Item-Sync Server

[![](https://img.shields.io/docker/pulls/absolutestratos/hkmw
)](https://hub.docker.com/r/absolutestratos/hkmw)

Hollow Knight Multiworld server guide.

## Quick Start

To launch vanilla HKMW server server on port 3333:

```bash
docker pull absolutestratos/hkmw:latest

docker run --rm -itd -p 3333:3333/tcp --name hkmw absolutestratos/hkmw:latest
```

This will start up the server.
To check to see if the docker container is running use `docker ps`:

```text
CONTAINER ID   IMAGE                        COMMAND                  CREATED          STATUS          PORTS
                  NAMES
6704833b9ac2   absolutestratos/hkmw:latest     "/opt/hkmw/hkmw.sh s…"   4 seconds ago    Up 4 seconds    0.0.0.0:3333->3333/tcp, :::3333->3333/tcp   hkmw
```

## HKMW Deployment

The following sections discuss various deployment options and more advanced usage.

### Configuring Running Server

As the server host, you may want to run some of hkmw commands as admin or watch the sever logs.
Assuming your server is already running using the command in the quick start section, re-attach your console to the running container:

```bash
docker attach hkmw
```

To then detach (exit the server console but keep the container running), use `CTRL-p CTRL-q`.

### Changing Port

To change the port hkmw uses, use the `PORT` environment variable.
Make sure the exposed port of the docker container is also updated.
For example:

```bash
docker run --rm -itd -e PORT=3334 -p 3334:3334/tcp --name hkmw absolutestratos/hkmw:latest 
```

### Changing Server Name

By default the server name will be "Stratos ItemSync".
You can change the title of the server with the `HKMW_SEVER_NAME` environment variable:

```bash
docker run --rm -itd -e HKMW_SEVER_NAME="My Server" -p 3333:3333/tcp --name hkmw absolutestratos/hkmw:latest 
```

### Caching Server Settings

Sometimes saving server settings, logs, etc is desired.
To have server files persist between starting and stopping the container, a local folder needs to be mounted into the container.

```bash
# Create a cache folder to save server files between container runs
mkdir -p ~/hkmw

docker run --rm -itd -p 3333:3333/tcp -v ~/hkmw/:/home/hkmw/ --name hkmw absolutestratos/hkmw:latest 
```

> You can also monitor server activity outside the docker container with `tail -n10 ~/hkmw/Logs/ServerLogYYYYMMDD-TTTTT.txt`

## Connecting Client Side

Test things are working, start up a Hollowknight game with Randomizer 4 and other needed mods installed:

- Create a new game.
- Select `Randomizer` and set up randomizer settings. For a standard game, just move the top left option to vanilla.
    - If you are using HKMP and want to sync randos between multiple people, go to `More Randomization Settings > Manage Settings Profiles` and share the settings code. This should make the seed in the main rando menu the same.
- `Begin Randomization` and confirm everything is consistent and `Proceed`
- Click `ItemSync` and enter in the VM IP with port 3333 (or whatever port you are using).
- Connect should bring up your item sync server name, click `Ready`
- When ALL players are in the ready list, `Begin ItemSync`

> Connecting to an item sync server happens before map creation, it is not possible for new players to connect if they were not part of the initialization process. You will need to remake the map and start over if someone wants to join.

## Building

To build your own docker container, use the following:

```bash
docker build -t hkmw:latest .
```

### Building the Server Files

Unfortunately, the developers do not ship a server build on their Github release.
The built stand alone server files are supplied on the [HKCloudServer releases](https://github.com/AbsoluteStratos/HKCloudServers/releases) for convience.
Building your own binaries works just like other Hollow Knight mods:

- Clone the [Github Repo](https://github.com/Shadudev/HollowKnight.MultiWorld) and checkout the release tag to use. Open this with Visual Studio Code 2022.
- You will need a few mod dependencies and update the `csproj` files to point to your Hollowknight game location.
- Switch build type to `Release` and build. Files needed will be in `HollowKnight.MultiWorld\MultiWorldServer\bin\Release`.
- Compress the outputs of that folder with:
    ```powershell
    Compress-Archive -Path Debug\* -DestinationPath HKISServer.zip
    ```

## References

Credit to HKMW:

- [Hollow Knight MultiWorld](https://github.com/Shadudev/HollowKnight.MultiWorld)
- [Sever Container](https://hub.docker.com/repository/docker/absolutestratos/hkmw/general)