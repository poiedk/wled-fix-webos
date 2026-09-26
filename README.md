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

## Current release

The first release is published:

- Version: **v1.0.0**
- IPK: `org.webosbrew.wledfix_1.0.1_all.ipk`
- Homebrew feed: `repo.json`

Release page:

```text
https://github.com/poiedk/wled-fix-webos/releases/tag/v1.0.0
```

## Add to Homebrew Channel

In **Homebrew Channel → Settings → Add repository**, add:

```text
https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json
```

You can also open the Add Repository screen over SSH:

```sh
luna-send -n 1 luna://com.webos.applicationManager/launch \
'{"id":"org.webosbrew.hbchannel","params":{"launchMode":"addRepository","url":"https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json"}}'
```

After adding the repository, **WLED Fix** should appear in Homebrew Channel and can be installed or updated from there.

## Install manually

The v1.0.0 IPK is available at:

```text
https://github.com/poiedk/wled-fix-webos/releases/download/v1.0.0/org.webosbrew.wledfix_1.0.1_all.ipk
```

If you copy it to the TV as `/tmp/org.webosbrew.wledfix_1.0.1_all.ipk`, install it with:

```sh
opkg install /tmp/org.webosbrew.wledfix_1.0.1_all.ipk
```

Then launch **WLED Fix** from the LG launcher.

## Manual run after installation

The discovery script ships inside the application:

```sh
sh /media/developer/apps/usr/palm/applications/org.webosbrew.wledfix/wled-auto.sh
```

## Build locally

```sh
chmod +x scripts/build-ipk.sh
./scripts/build-ipk.sh
```

The package is written to:

```text
dist/org.webosbrew.wledfix_<version>_all.ipk
```

## Safety

Before changing Hyperion's database, WLED Fix refreshes:

```text
/home/root/.hyperion/db/hyperion.db.wled-auto-backup
```

The script only updates the WLED device entry for Hyperion instance 0. If Hyperion already points to the detected WLED IP, it exits without modifying the database or restarting Hyperion.

## Future releases

For future versions:

1. update the version in `app/appinfo.json`,
2. commit the change,
3. create a matching tag such as `v1.1.0`,
4. push the tag.

The **Release** GitHub Actions workflow builds the IPK, generates `repo.json`, calculates the SHA-256 hash, and publishes both files to the release.

The Homebrew repository URL stays the same because it always points to the latest release.


## v1.0.1 packaging fix

v1.0.1 fixes the webOS package layout used by v1.0.0. The app is now packaged under:

```text
/usr/palm/applications/org.webosbrew.wledfix
```

inside the IPK data archive, which is the layout expected by the webOS installer.

The custom feed also uses `shortDescription`, so Homebrew Channel can display the package description correctly.

If v1.0.0 failed with **Failed to extract package**, refresh/reopen Homebrew Channel and install v1.0.1.
