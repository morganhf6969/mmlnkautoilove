#!/usr/bin/env python3
"""
Scarica tutti i link video di un canale TikTok e genera
un file JSON pronto per l'import in MemoLink.

USO:
    pip3 install yt-dlp
    python3 tiktok_to_memolink.py @iloveabitini_ "I ❤️ Abitini"

IMPORT IN MEMOLINK:
    Impostazioni → Importa backup → seleziona memolink_tiktok_import.json
"""

import sys
import json
import subprocess
import re
from datetime import datetime, timezone

def get_tiktok_videos(channel: str) -> list[dict]:
    """Usa yt-dlp per estrarre i metadati di tutti i video del canale."""
    url = f"https://www.tiktok.com/{channel}"
    if not channel.startswith("@"):
        url = f"https://www.tiktok.com/@{channel}"

    print(f"📥 Recupero video da {url} ...")

    cmd = [
        sys.executable, "-m", "yt_dlp",
        "--flat-playlist",
        "--playlist-end", "200",
        "--print", "%(webpage_url)s\t%(title)s\t%(id)s\t%(thumbnail)s",
        "--cookies-from-browser", "chrome",
        "--no-warnings",
        "--quiet",
        url,
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

    if result.returncode != 0:
        print(f"❌ Errore yt-dlp:\n{result.stderr}")
        sys.exit(1)

    videos = []
    for line in result.stdout.strip().splitlines():
        parts = line.split("\t")
        if len(parts) >= 1:
            thumbnail = parts[3].strip() if len(parts) > 3 else None
            # yt-dlp restituisce "NA" se non disponibile
            if thumbnail == "NA" or thumbnail == "":
                thumbnail = None
            videos.append({
                "url": parts[0].strip(),
                "title": parts[1].strip() if len(parts) > 1 else "",
                "video_id": parts[2].strip() if len(parts) > 2 else "",
                "thumbnail": thumbnail,
            })

    print(f"✅ Trovati {len(videos)} video")
    return videos


def detect_platform(url: str) -> str:
    url = url.lower()
    if "tiktok.com" in url:
        return "tiktok"
    if "instagram.com" in url:
        return "instagram"
    if "youtube.com" in url or "youtu.be" in url:
        return "youtube"
    return "manual"


def extract_hashtags(title: str) -> list[str]:
    """Estrae hashtag dal titolo del video."""
    return [tag.lstrip("#").lower() for tag in re.findall(r"#\w+", title)]


def build_memolink_json(videos: list[dict], category_name: str) -> dict:
    """Costruisce il JSON nel formato MemoLink."""
    items = []
    for v in videos:
        hashtags = extract_hashtags(v["title"])
        og_title = re.sub(r"#\w+", "", v["title"]).strip() or None
        items.append({
            "url": v["url"],
            "platform": detect_platform(v["url"]),
            "category_name": category_name,   # risolto per nome nell'import
            "hashtags": ",".join(hashtags),
            "og_title": og_title,
            "og_image": v.get("thumbnail"),
            "title": og_title,
            "thumbnail_url": v.get("thumbnail"),
            "created_at": datetime.now(timezone.utc).isoformat(),
        })

    return {
        "version": 1,
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "categories": [
            {"name": category_name, "icon_code": 9, "position": 0}
        ],
        "items": items,
    }


def main():
    if len(sys.argv) < 2:
        print("USO: python3 tiktok_to_memolink.py @canale [\"Nome Categoria\"]")
        sys.exit(1)

    channel = sys.argv[1]
    category = sys.argv[2] if len(sys.argv) > 2 else "I ❤️ Abitini"

    videos = get_tiktok_videos(channel)
    if not videos:
        print("⚠️  Nessun video trovato.")
        sys.exit(0)

    data = build_memolink_json(videos, category)

    out_file = "memolink_tiktok_import.json"
    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"\n🎉 File generato: {out_file}")
    print(f"   {len(data['items'])} link → categoria \"{category}\"")
    print("\n📱 Ora in MemoLink: Impostazioni → Importa backup → seleziona il file")


if __name__ == "__main__":
    main()
