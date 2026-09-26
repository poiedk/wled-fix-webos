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

## Install

Download the latest `.ipk` from GitHub Releases and install it on the TV:

```sh
opkg install /tmp/org.webosbrew.wledfix_1.0.0_all.ipk
```

Then launch **WLED Fix** from the LG launcher.

## Manual run

The script ships inside the app package. On a standard Homebrew install:

```sh
sh /media/developer/apps/usr/palm/applications/org.webosbrew.wledfix/wled-auto.sh
```

## Safety

Before changing Hyperion's DB:

```text
/home/root/.hyperion/db/hyperion.db.wled-auto-backup
```

is refreshed from the current database.

The script only updates the WLED device entry for Hyperion instance 0.

## Build

```sh
./scripts/build-ipk.sh
```

The package is written to `dist/`.

## Release

Push a tag such as `v1.0.0`. GitHub Actions builds the IPK and publishes it as a Release asset.


## Add to Homebrew Channel

After the first tagged release is published, add this custom repository URL in **Homebrew Channel → Settings → Add repository**:

```text
https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json
```

The feed always points to the latest GitHub Release and includes the SHA-256 hash of the IPK, so Homebrew Channel can install and update WLED Fix directly.
