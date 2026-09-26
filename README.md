# WLED Fix for webOS

WLED Fix is a remote-friendly utility for rooted LG webOS TVs running Hyperion.NG with WLED.

## Current release

**v1.1.2**

Highlights:

- TV-native dark UI designed for remote control
- **BACK only navigates back; Exit is a separate action**
- Simple and Advanced Settings
- faster WLED discovery
- Hyperion target verification after a fix
- optional LED test
- configurable backup retention
- optional technical details and verbose logging
- dark launcher icon

## Homebrew Channel repository

Add this URL once in **Homebrew Channel → Settings → Add repository**:

```text
https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json
```

SSH shortcut:

```sh
luna-send -n 1 luna://com.webos.applicationManager/launch \
'{"id":"org.webosbrew.hbchannel","params":{"launchMode":"addRepository","url":"https://github.com/poiedk/wled-fix-webos/releases/latest/download/repo.json"}}'
```

## Simple Settings

- **Auto scan on launch** — ON
- **Auto close after success** — OFF
- **Verify Hyperion after fix** — ON
- **Test LEDs after fix** — OFF
- **Show technical details** — OFF

## Advanced Settings

- **Fast scan** — ON
- **Full subnet scan fallback** — ON
- **Scan timeout** — 1 or 2 seconds
- **Hyperion instance** — 0–3
- **Restart Hyperion after IP change** — ON
- **Network interface** — wlan0 / eth0
- **Backup Hyperion DB before change** — ON
- **Keep previous backups** — 1 / 3 / 5
- **Verbose logging** — OFF
- **Reset settings to defaults**

Settings are stored locally by the webOS app and persist across launches.

## Discovery strategy

With Fast Scan enabled, WLED Fix tries:

1. the current Hyperion target,
2. devices already present in the TV ARP table,
3. a full /24 scan only when needed.

WLED is confirmed through its `/json/info` endpoint and `"brand":"WLED"`.

## What happens when the WLED IP changes

WLED Fix can:

1. create a Hyperion DB backup,
2. update `host` and `hostList`,
3. restart Hyperion,
4. verify that `LEDDEVICE` is enabled again,
5. optionally send a short LED test.

If the existing target is already correct, the database is not modified.

## Requirements

- rooted LG webOS TV
- Homebrew Channel
- Hyperion.NG loader
- WLED on the same IPv4 /24 network
- `sqlite3`, `wget`, `ifconfig`

Tested with LG webOS 3.4.x, Hyperion.NG 2.0.16 and WLED 0.16.0.

## Build

Packages are built with the official webOS `ares-package` CLI.

```sh
npm install -g @webos-tools/cli
chmod +x scripts/build-ipk.sh
./scripts/build-ipk.sh
```

Output is written to `dist/`.

## Releases

Creating a `v*` tag triggers GitHub Actions to:

1. build the IPK with `ares-package`,
2. generate `repo.json`,
3. calculate the IPK SHA-256,
4. publish both files as GitHub Release assets.

The Homebrew repository URL remains unchanged between releases.


## v1.1.2

- BACK no longer exits the app from the main screen.
- Settings BACK returns to the previous screen.
- Added a dedicated **Exit App** action with confirmation.
- Redesigned the main screen with a cleaner status panel and three large TV-friendly actions.
- Replaced the launcher/Homebrew icon with a clean 256x256 PNG.
- Kept the dark launcher tile metadata.
