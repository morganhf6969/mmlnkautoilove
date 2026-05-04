#!/usr/bin/env python3
"""
Scraper Mac per @iloveabitini — gira ogni 6 ore via LaunchAgent.
Scrapa Instagram e aggiorna data/pending.json su GitHub.
"""

import base64
import json
import logging
import subprocess
from datetime import datetime, timezone
from pathlib import Path

import requests
from instagrapi import Client
from instagrapi.exceptions import LoginRequired

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Configurazione ────────────────────────────────────────────────────────────

TARGET_ACCOUNT = "iloveabitini"
MAX_POSTS      = 50
REPO_ROOT      = Path(__file__).parent.parent
SESSION_FILE   = Path(__file__).parent / ".instagram_session.json"
PENDING_FILE   = REPO_ROOT / "data" / "pending.json"
FEED_FILE      = REPO_ROOT / "data" / "iloveabitini_feed.json"

# ── Instagram ─────────────────────────────────────────────────────────────────

def instagram_client() -> Client:
    if not SESSION_FILE.exists():
        log.error("Sessione non trovata. Esegui prima gen_session.py")
        raise SystemExit(1)
    cl = Client()
    cl.delay_range = [2, 5]
    cl.load_settings(SESSION_FILE)
    cl.get_timeline_feed()
    log.info("Sessione Instagram OK.")
    return cl

def scrape_new(cl: Client, existing_urls: set) -> list:
    user_id = cl.user_info_by_username_v1(TARGET_ACCOUNT).pk
    medias  = cl.user_medias_v1(user_id, amount=MAX_POSTS)
    log.info("Post recuperati: %d", len(medias))

    new = []
    for m in medias:
        url = f"https://www.instagram.com/p/{m.code}/"
        if url in existing_urls:
            continue
        og_image = str(m.thumbnail_url) if m.thumbnail_url else None
        og_title = (m.caption_text or "").strip()[:120] or f"@{TARGET_ACCOUNT}"
        new.append({
            "url": url,
            "platform": "instagram",
            "og_title": og_title,
            "og_image": og_image,
            "created_at": (
                m.taken_at.isoformat() if m.taken_at
                else datetime.now(timezone.utc).isoformat()
            ),
        })
        log.info("  + %s", url)
    return new

# ── File helpers ──────────────────────────────────────────────────────────────

def load_json(path: Path) -> dict:
    if path.exists():
        return json.loads(path.read_text())
    return {"version": 1, "last_updated": None, "items": []}

def save_json(path: Path, data: dict):
    data["last_updated"] = datetime.now(timezone.utc).isoformat()
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2))

# ── Git push ──────────────────────────────────────────────────────────────────

def git_push(n: int):
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    try:
        subprocess.run(
            ["git", "-C", str(REPO_ROOT), "add",
             "data/pending.json"],
            check=True
        )
        subprocess.run(
            ["git", "-C", str(REPO_ROOT), "commit",
             "-m", f"🕷️ {n} nuovi post in pending [{ts}]"],
            check=True
        )
        subprocess.run(
            ["git", "-C", str(REPO_ROOT), "push"],
            check=True
        )
        log.info("Push GitHub completato.")
    except subprocess.CalledProcessError as e:
        log.error("Errore git: %s", e)

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    log.info("=== Scraper Mac @%s ===", TARGET_ACCOUNT)

    pending = load_json(PENDING_FILE)
    feed    = load_json(FEED_FILE)

    existing_urls = (
        {i["url"] for i in feed.get("items", [])} |
        {i["url"] for i in pending.get("items", [])}
    )
    log.info("URL già noti: %d", len(existing_urls))

    try:
        cl       = instagram_client()
        new_posts = scrape_new(cl, existing_urls)
    except LoginRequired:
        log.error("Sessione scaduta. Rigenera con gen_session.py")
        return
    except Exception as e:
        log.error("Errore scraping: %s", e)
        return

    if not new_posts:
        log.info("Nessun nuovo post.")
        return

    pending["items"] = new_posts + pending.get("items", [])
    save_json(PENDING_FILE, pending)
    log.info("%d nuovi post aggiunti al pending.", len(new_posts))

    git_push(len(new_posts))

if __name__ == "__main__":
    main()
