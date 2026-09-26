# WLED Fix for webOS

One-click WLED rediscovery for rooted LG webOS TVs running Hyperion.NG.

## Why

Hyperion can store a WLED mDNS service name, but mDNS discovery may fail on phone hotspots or networks that isolate multicast. WLED Fix avoids that dependency by discovering WLED over HTTP on the TV's current IPv4 subnet.

## What it does

- Detects the TV's current Wi-Fi IPv4 subnet.
- Scans the local /24 for a WLED device via `/json/info`.
- Verifies `"brand":"WLED"`.
- Reads Hyperion's current WLED target from `hyperion.db`.
- If the IP changed, backs up the database, updates only `host` and `hostList`, and restarts Hyperion.
- If the target is already correct, exits without touching Hyperion.
- Runs from a launcher app on the TV.

## Requirements

- Rooted LG webOS TV
- Homebrew Channel
- Hyperion.NG loader
- WLED on the same IPv4 /24 subnet as the TV
- `sqlite3`, `wget`, `ifconfig`

## Tested setup

- LG webOS 3.4.x
- Hyperion.NG 2.0.16
- WLED 0.16.0
- DDP streaming

## Current status

The source code, IPK build workflow, and Homebrew custom-feed generator are in place.

**There is currently no GitHub Release published yet.**  
Because of that, this Homebrew repository URL does **not** work yet:

```text
https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json
```

It becomes valid automatically after the first tagged release is published.

## Build locally

```sh
chmod +x scripts/build-ipk.sh
./scripts/build-ipk.sh
```

The package is written to:

```text
dist/org.webosbrew.wledfix_<version>_all.ipk
```

## Create the first release

Create and push the first version tag:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The **Release** GitHub Actions workflow will then:

1. build the IPK,
2. generate `repo.json`,
3. calculate and include the IPK SHA-256 hash,
4. create the GitHub Release,
5. upload both the IPK and `repo.json` as release assets.

After that, the stable custom-repository URL is:

```text
https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json
```

## Add to Homebrew Channel

Only **after the first release exists**, add the repository in:

**Homebrew Channel → Settings → Add repository**

using:

```text
https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json
```

You can also open the Add Repository screen over SSH:

```sh
luna-send -n 1 luna://com.webos.applicationManager/launch \
'{"id":"org.webosbrew.hbchannel","params":{"launchMode":"addRepository","url":"https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json"}}'
```

## Install from an IPK manually

Once an IPK exists, copy it to the TV and install it, for example:

```sh
opkg install /tmp/org.webosbrew.wledfix_1.0.0_all.ipk
```

Then launch **WLED Fix** from the LG launcher.

## Manual run after installation

The script ships inside the app package:

```sh
sh /media/developer/apps/usr/palm/applications/org.webosbrew.wledfix/wled-auto.sh
```

## Safety

Before changing Hyperion's database, WLED Fix refreshes:

```text
/home/root/.hyperion/db/hyperion.db.wled-auto-backup
```

The script only updates the WLED device entry for Hyperion instance 0. If Hyperion already points to the detected WLED IP, it exits without modifying the database or restarting Hyperion.

## Release updates

For future versions:

1. update the version in `app/appinfo.json`,
2. commit the change,
3. create a matching tag such as `v1.1.0`,
4. push the tag.

The Homebrew feed URL stays the same because it always resolves through the latest GitHub Release.
