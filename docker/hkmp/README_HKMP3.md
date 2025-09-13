# Notes for hosting HKMP 3

To set up a server for HKMP the docker image is a little different.

## Provision Machine

The requirements of HKMP 3.0 is a little heavier, so expect needing a more expensive machine

- E2 - Medium
- 20Gb disk space
- Premium Tier

For the rest follow the same isntructions in the GCP section with docker installed.

## Copy the HKMPServer.zip to the machine

Download the server zip from Patreon and move it to the VM with scp:

```bash
scp  -i ~/.ssh/gcp HKMPServer.zip <username>@<external IP>:~
```

Unzip this file into `~/hkmp`

```bash
sudo apt-get install unzip
unzip HKMPServer.zip -d hkmp
```

## Pull Wine Docker Image

Mono, used for hkmp 2.0 is depricated in favor of wineHQ and HKMP 3.0 needs dot net dependencies.
So rather than trying to install that ourselves lets use the [docker-wine-dotnet](https://github.com/NyaMisty/docker-wine-dotnet) container:

```bash
docker pull nyamisty/docker-wine-dotnet:win64-stable
```

## Start HKMP server with docker

Now lets spin up the container with our mounted files:

```bash
docker run --rm -it -p 2222:2222/udp -v ~/hkmp/:/home/hkmp/ nyamisty/docker-wine-dotnet:win64-stable bash
```

Inside the container start the HKMP server with:

```bash
cd /home/hkmp
wine HKMPServer.exe 2222
```

Should output something like:

```text
00f8:err:ntoskrnl:ZwLoadDriver failed to create driver L"\\Registry\\Machine\\System\\CurrentControlSet\\Services\\winebth": c00000e5
[INFO] [HkmpServer.HkmpServer] Starting server v3.2.0-es.1
[DEBUG] [Hkmp.Api.Addon.AddonLoader] Skipping loading assembly at: Z:\home\hkmp\BouncyCastle.Cryptography.dll
[DEBUG] [Hkmp.Api.Addon.AddonLoader] Skipping loading assembly at: Z:\home\hkmp\HKMP.dll
[DEBUG] [Hkmp.Api.Addon.AddonLoader] Skipping loading assembly at: Z:\home\hkmp\Newtonsoft.Json.dll
[DEBUG] [Hkmp.Game.Server.ServerManager] Registering packet handlers
[INFO] [Hkmp.Networking.Server.NetServer] Starting NetServer on port 2222
[INFO] [Hkmp.Networking.Server.ServerTlsServer] LoadOrGenerateECDHKeyPair: Z:\home\hkmp\key.pem
[INFO] [Hkmp.Networking.Server.ServerTlsServer] KeyPair file exists, loading...
[INFO] [Hkmp.Networking.Server.ServerTlsServer] LoadOrGenerateCertificate: Z:\home\hkmp\cert.cer
[INFO] [Hkmp.Networking.Server.ServerTlsServer] Certificate file exists, loading...
[DEBUG] [Hkmp.Networking.Server.DtlsServer] Creating new ServerDatagramTransport for handling new connection
````

This will start the server, you can type hkmp [commands](https://github.com/Extremelyd1/HKMP?tab=readme-ov-file#usage) in this console if you want.
E.g.

```bash
announce hi
```

To detach from the server use Ctrl + p then Ctrl + q, `docker ps` should show it still running.
Since we have mounted the server, it will save the game state in the `~/hkmp` folder, to reset the save, delete that and start the server.

## TIP: Create a machine image

A good tip when the instance is running fine, click the VM, then create a machine image up top.
This will allow you to duplicate the VM onto different machines in different locations as needed.
https://www.gcping.com/ is good to figure out which centers have lower ping.