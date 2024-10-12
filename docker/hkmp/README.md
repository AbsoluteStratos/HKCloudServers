# Hollow Knight Multiplayer (HKMP) Server

[![](https://img.shields.io/docker/pulls/absolutestratos/hkmp
)](https://hub.docker.com/r/absolutestratos/hkm)

Hollow Knight Multiplayer server guide.

## Quick Start

To launch vanilla HKMP server server on port 2222:

```bash
docker pull absolutestratos/hkmp:latest

docker run --rm -itd -p 2222:2222/udp --name hkmp absolutestratos/hkmp:latest
```

This will start up the server.
To check to see if the docker container is running use `docker ps`:

```text
CONTAINER ID   IMAGE                        COMMAND                  CREATED         STATUS         PORTS                                       NAMES
08159d7b6d21   absolutestratos/hkmp:latest   "/opt/hkmp/hkmp.sh s…"   3 seconds ago   Up 2 seconds   0.0.0.0:2222->2222/udp, :::2222->2222/udp   hkmp
```

## HKMP Deployment

The following sections discuss various deployment options and more advanced usage.

### Configuring Running Server

As the server host, you may want to run some of [HKMP commands](https://github.com/Extremelyd1/HKMP?tab=readme-ov-file#usage) as admin.
Assuming your server is already running using the command in the quick start section, re-attach your console to the running container:

```bash
docker attach hkmp
```

This will allow you to execute server commands, e.g. try running `announce hello world!`.
To then detach (exit the server console but keep the container running), use `CTRL-p CTRL-q`.

#### Whitelist

To turn on authentication in the server you can control the whitelist via the server console, or give admin to a specific user with `auth <username>`.
Its easy with the server console, assuming you are attached to the container start with creating a white list:

1.  In server console `whitelist on`
2. Add / pre-add a user with `whitelist add <username>`. If the user is already on the sever this will add thier auth ID to the `/home/hkmp/whitelist.json` file. Otherwise it will pre-add the user name then save it for the first person that joins with that username.

See [whitelist section](https://github.com/Extremelyd1/HKMP/?tab=readme-ov-file#authenticationauthorization) of the HKMP Readme for more details.

### Changing Port

To change the port HKMP uses, use the `PORT` environment variable.
Make sure the exposed port of the docker container is also updated.
For example:

```bash
docker run --rm -itd -e PORT=2223 -p 2223:2223/udp --name hkmp absolutestratos/hkmp:latest 
```

### Caching Server Settings

Sometimes saving server settings, plug-ins, etc is desired.
To have server files persist between starting and stopping the container, a local folder needs to be mounted into the container.

```bash
# Create a cache folder to save server files between container runs
mkdir -p ~/hkmp

docker run --rm -itd -p 2222:2222/udp -v ~/hkmp/:/home/hkmp/ --name hkmp absolutestratos/hkmp:latest 
```

> You can also monitor server activity outside the docker container with `tail -n10 ~/hkmp/logs/server.log`

### Installing Plug-Ins

Some HKMP mods require server side plug-ins.
There are some convient commands inside the container that can help with this.
To install a plug in, the server needs to be started in interactive mode.

```bash
docker run --rm -it -p 2222:2222/udp -v ~/hkmp/:/home/hkmp/ --name hkmp absolutestratos/hkmp:latest bash
```

Once inside the container, use the `hkmp` command to install plug-ins automatically:

- `hkmp plugin-pouch` - Built in install for [HKMP.Pouch](https://github.com/PrashantMohta/HkmpPouch)
- `hkmp plugin-health` - Built in install for [HKMP.Healthdisplay](https://github.com/TheMulhima/HKMP.HealthDisplay) 
- `hkmp plugin-trail` - Built in install for [HKMP.PlayerTrail](https://github.com/TheMathGeek314/PlayerTrail)
- Any non supported one with `hkmp plugin <Author> <Repo> <Plugin Release ZIP name>`
- Or manually place the files in the mounted folder (e.g. `~/hkmp/`) on you machine.

Once all your desired plug-ins are installed, start the server with `hkmp start`.
If everything boots up properly, detach from the container using `CTRL-p CTRL-q`.

### Server Shut Down

```bash
docker stop hkmp
```

## Connecting Client Side

Test things are working, start up a Hollowknight game with HKMP installed:

- When launched, use the chat key (default is `t`) and `/connect <external-ip>:2222 stratos` or you can press esc and use the UI.
- This should connect you to the server and a name should appear over your head.
- In your docker console, it should should show something like:
    ```bash
    [INFO] Received login request from 'stratos'
    [INFO] Received login request from IP: <IP Address>, username: stratos
    [INFO]   Client tries to connect with following addons:
    [INFO] Received HelloServer data from (0, stratos)
    ```

## Building

To build your own docker container, use the following:

```bash
docker build -t hkmp:latest .
```

## References

Credit to HKMP and HKMP Docker repos:

- [Hollow Knight MultiPlayer](https://github.com/Extremelyd1/HKMP)
- [HKMP Docker](https://github.com/maximalmax90/HKMPDocker)
- [Sever Container](https://hub.docker.com/repository/docker/absolutestratos/hkmp/general)
