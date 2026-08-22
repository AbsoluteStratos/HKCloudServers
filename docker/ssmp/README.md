# Notes for hosting SSMP (Silksong Multiplayer)

[SSMP](https://github.com/Extremelyd1/SSMP) is the Hollow Knight: Silksong multiplayer mod, made by the same author as HKMP.
There is no purpose built container for it yet, so hosting works much like [HKMP 3](../hkmp/README_HKMP3.md): mount the standalone server files into a generic container and run them.

> [!NOTE]
> Unlike HKMP 3, wine is not needed here. The SSMP releases include a Linux build of the server, so the official .NET runtime image is enough.

## Provision Machine

SSMP is a .NET 9 server and Silksong sessions are about as demanding as HKMP 3, so use a similar machine:

- E2 - Medium
- 20Gb disk space
- Premium Tier

For the rest follow the same instructions in the GCP section with docker installed.

SSMP defaults to port `26960` over UDP, so when creating the firewall rule described in the [GCP readme](../../gcp/README.md), add `UDP` port `26960` alongside the HKMP and HKMW ports.

## Download the server files

The standalone server is a public release, so it can be pulled straight down onto the VM (no Patreon required):

```bash
sudo apt-get install unzip
curl -LO https://github.com/Extremelyd1/SSMP/releases/latest/download/SSMPServer-linux.zip
unzip SSMPServer-linux.zip -d ssmp
```

The zip has no top level folder, so this leaves the server files in `~/ssmp`.

## Pull .NET Docker Image

The Linux server build is framework dependent (`net9.0`), so the official Microsoft runtime image can run it as is:

```bash
docker pull mcr.microsoft.com/dotnet/runtime:9.0
```

## Start SSMP server with docker

Now lets spin up the container with our mounted files:

```bash
docker run --rm -it -p 26960:26960/udp -v ~/ssmp/:/home/ssmp/ mcr.microsoft.com/dotnet/runtime:9.0 bash
```

Inside the container start the SSMP server with:

```bash
cd /home/ssmp
dotnet SSMPServer.dll 26960
```

> Invoking `dotnet SSMPServer.dll` avoids relying on the executable bit surviving the unzip. `chmod +x SSMPServer && ./SSMPServer 26960` works equally well.

Should output something like:

```text
[INFO] Server settings did not exist yet, creating new server settings file
[INFO] Console settings did not exist yet, creating new console settings file
[INFO] Starting server v0.3.1
[INFO] Starting NetServer on port 26960
```

This will start the server, you can type SSMP [commands](https://github.com/Extremelyd1/SSMP?tab=readme-ov-file#commands) in this console without the leading slash.
E.g.

```bash
announce hi
```

The console also has `exit` to shut the server down gracefully and `log <level>` to change which messages are printed.

To detach from the server use Ctrl + p then Ctrl + q, `docker ps` should show it still running.
Since we have mounted the server, the settings files, whitelist and logs are written to the `~/ssmp` folder:

- `serversettings.json` - the gameplay settings (pvp, teams, damage values, etc.)
- `consolesettings.json` - the default port used when no port argument is given
- `logs/server.log` - can be tailed from outside the container with `tail -n10 ~/ssmp/logs/server.log`

## Installing Addons

Popular SSMP mods are networked addons, meaning they have a server half that must be installed on the server as well as the client half in your BepInEx plugins folder:

- [SSMP Essentials](https://thunderstore.io/c/hollow-knight-silksong/p/BobbyTheCatfish/SSMPEssentials/) - teleports, healthbars, spectating and death messages
- [BasicItemSync](https://thunderstore.io/c/hollow-knight-silksong/p/BobbyTheCatfish/BasicItemSync/) - syncs items, progression and shortcuts
- [BasicEnemySync](https://thunderstore.io/c/hollow-knight-silksong/p/Brothergaming52/BasicEnemySync/) - syncs enemies and boss phases, and adds a downed / cocoon revive system

Each is built as a single assembly containing both the client and the server addon, so the same DLL out of the Thunderstore package is what the server needs.
On start up SSMP scans its own directory for any `*.dll` and loads every class extending `ServerAddon`, so installing an addon is just a matter of dropping the DLL into the mounted `~/ssmp` folder before starting the server.

Thunderstore download links need an explicit version, so grab the version you intend to play with:

```bash
# Run these on the VM, not inside the container
curl -L -o /tmp/essentials.zip https://thunderstore.io/package/download/BobbyTheCatfish/SSMPEssentials/0.1.2/
curl -L -o /tmp/itemsync.zip https://thunderstore.io/package/download/BobbyTheCatfish/BasicItemSync/0.1.1/
curl -L -o /tmp/enemysync.zip https://thunderstore.io/package/download/Brothergaming52/BasicEnemySync/1.0.1/

for mod in essentials itemsync enemysync; do
    unzip -o /tmp/$mod.zip -d /tmp/$mod
    find /tmp/$mod -name '*.dll' -exec cp {} ~/ssmp/ \;
done
```

Mod managers lay their packages out slightly differently, hence the `find` rather than a plain `cp` of the zip root.
Only the mod's own DLL is wanted. The `manifest.json`, `icon.png` and readme in the package are for mod managers, and the client side dependencies (BepInEx, AssetHelper) are not needed on the server.

Start the server again and each addon should be picked up in the log:

```text
[INFO] Trying to load assembly at: /home/ssmp/BasicItemSync.dll
[INFO]   Found SSMP.Api.Server.ServerAddon extending class, constructing addon
[INFO] Assigned addon BasicItemSync v0.1.1 ID: 0
[INFO] Initializing server addon: BasicItemSync 0.1.1
```

Be aware that the addon identifier is not always the Thunderstore package name.
BasicEnemySync ships `EnemySyncing.dll` and registers itself as `EnemySyncingAddon v1.0.1`, so that is what shows up in the log and in the client's addon list.

> [!IMPORTANT]
> Every player must run the exact same set of networked addons at the exact same versions as the server.
> SSMP matches the client's addon list against the server's by name and version and rejects the login if the count differs or any entry does not match.
> In practice this means one player missing BasicItemSync, or running a different version to the server, will simply fail to connect.

> [!NOTE]
> These addons are early in development and are not tested by this repository against a headless server.
> If an addon fails to load you will see a `Could not initialize addon <name>` warning in the server log instead of the lines above, and clients will then be rejected because the server has no matching addon.
> Check the addon's own repo ([SSMP.Essentials](https://github.com/BobbyTheCatfish/SSMP.Essentials), [Silksong-BasicItemSync](https://github.com/BobbyTheCatfish/Silksong-BasicItemSync), [ssmp-enemy-sync](https://github.com/Brothergaming52/ssmp-enemy-sync)) or the SSMP Discord if that happens.

Two gameplay caveats worth knowing before committing a save to these:

- BasicItemSync only supports fully synchronous playthroughs. All players need to start from fresh save files and nobody can join part way through, since items are only sent to players connected at the time.
- BasicEnemySync is explicitly flagged by its author as a work in progress that can cause game breaking bugs, so back up save files first.

## Connecting Client Side

Start up Silksong with SSMP installed (it needs the [BepInExPack for Silksong](https://thunderstore.io/c/hollow-knight-silksong/p/BepInEx/BepInExPack_Silksong/)):

- From the main menu choose `Start Multiplayer`.
- Pick the direct connection option and enter `<external ip>:26960`.
- Select a save file when prompted. This save is local only and does not sync to the server.
- Chat opens with `y` by default, use `/list` to confirm who is connected.

> SSMP also ships Steam lobbies and a matchmaking service with NAT hole punching. Those are meant for peer hosted games, a cloud VM only needs the direct connection path documented above.

## TIP: Create a machine image

A good tip when the instance is running fine, click the VM, then create a machine image up top.
This will allow you to duplicate the VM onto different machines in different locations as needed.
https://www.gcping.com/ is good to figure out which centers have lower ping.

## References

- [Silksong Multiplayer](https://github.com/Extremelyd1/SSMP)
- [SSMP Discord](https://discord.gg/KbgxvDyzHP)
