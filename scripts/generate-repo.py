#!/usr/bin/env python3
import hashlib
import json
import os
import pathlib
import sys

if len(sys.argv) != 3:
    raise SystemExit("usage: generate-repo.py <tag> <ipk-path>")

tag = sys.argv[1]
ipk = pathlib.Path(sys.argv[2])
version = tag[1:] if tag.startswith("v") else tag
repo = os.environ.get("GITHUB_REPOSITORY", "poiedk/wled-fix-webos")
owner, name = repo.split("/", 1)

sha256 = hashlib.sha256(ipk.read_bytes()).hexdigest()
asset_name = ipk.name

icon_url = f"https://raw.githubusercontent.com/{repo}/main/app/icon.png"
source_url = f"https://github.com/{repo}"
ipk_url = f"https://github.com/{repo}/releases/download/{tag}/{asset_name}"

payload = {
    "paging": {"page": 1, "count": 1, "maxPage": 1, "itemsTotal": 1},
    "packages": [
        {
            "id": "org.webosbrew.wledfix",
            "title": "WLED Fix",
            "description": "One-click WLED rediscovery for Hyperion.NG on rooted LG webOS TVs.",
            "iconUri": icon_url,
            "manifest": {
                "id": "org.webosbrew.wledfix",
                "version": version,
                "type": "web",
                "title": "WLED Fix",
                "appDescription": "Finds WLED on the current network and updates Hyperion's WLED target automatically.",
                "iconUri": icon_url,
                "sourceUrl": source_url,
                "rootRequired": True,
                "ipkUrl": ipk_url,
                "ipkHash": {"sha256": sha256},
            },
        }
    ],
}

out = pathlib.Path("dist/repo.json")
out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
print(out)
print(sha256)
