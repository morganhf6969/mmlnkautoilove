#!/usr/bin/env python3
"""
Scarica i thumbnail per ogni link in iloveabitini_default.json,
li salva in assets/images/iloveabitini/ e aggiorna il JSON
con il path locale (assets/images/iloveabitini/thumb_N.jpg).

USO:
    python3 scripts/fetch_thumbnails.py
"""

import sys
import json
import subprocess
import urllib.request
from pathlib import Path
from typing import Optional

ASSET_FILE = Path(__file__).parent.parent / "assets/data/iloveabitini_default.json"
THUMB_DIR  = Path(__file__).parent.parent / "assets/images/iloveabitini"
THUMB_DIR.mkdir(parents=True, exist_ok=True)


def fetch_thumbnail_url(url: str) -> Optional[str]:
    cmd = [
        sys.executable, "-m", "yt_dlp",
        "--skip-download",
        "--print", "%(thumbnail)s",
        "--cookies-from-browser", "chrome",
        "--no-warnings",
        url,
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        lines = [l.strip() for l in result.stdout.splitlines() if l.strip()]
        thumb = lines[-1] if lines else ""
        if thumb and thumb != "NA" and thumb.startswith("http"):
            return thumb
    except Exception:
        pass
    return None


def download_image(url: str, dest: Path) -> bool:
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=15) as resp:
            dest.write_bytes(resp.read())
        return True
    except Exception as e:
        print(f" download error: {e}", end="")
        return False


def main():
    with open(ASSET_FILE, "r", encoding="utf-8") as f:
        items = json.load(f)

    total = len(items)
    updated = 0

    for i, item in enumerate(items, 1):
        dest = THUMB_DIR / f"thumb_{i:03d}.jpg"
        asset_path = f"assets/images/iloveabitini/thumb_{i:03d}.jpg"

        # Se il file locale esiste già, aggiorna solo il JSON
        if dest.exists():
            item["og_image"] = asset_path
            updated += 1
            print(f"[{i}/{total}] ✅ già scaricato")
            continue

        print(f"[{i}/{total}] 🔍 {item['url'][:55]}", end=" ... ", flush=True)

        thumb_url = fetch_thumbnail_url(item["url"])
        if not thumb_url:
            print("⚠️  URL non trovato")
            item["og_image"] = None
            continue

        ok = download_image(thumb_url, dest)
        if ok:
            item["og_image"] = asset_path
            updated += 1
            print("✅")
        else:
            print("❌")
            item["og_image"] = None

    with open(ASSET_FILE, "w", encoding="utf-8") as f:
        json.dump(items, f, ensure_ascii=False, indent=2)

    print(f"\n🎉 {updated}/{total} thumbnail salvati in {THUMB_DIR}")


if __name__ == "__main__":
    main()
