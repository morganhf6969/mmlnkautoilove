#!/usr/bin/env python3
"""
Scraper Termux per @iloveabitini — gira ogni 6 ore via cron.
Usa instaloader (niente sessione) e aggiorna pending.json su GitHub via API.
"""

import base64
import json
import logging
import os
import sys
from datetime import datetime, timezone

import instaloader
import requests

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Configurazione ────────────────────────────────────────────────────────────

TARGET_ACCOUNT = "iloveabitini"
MAX_POSTS      = 50
GITHUB_TOKEN   = os.environ.get("GITHUB_TOKEN", "")
GITHUB_REPO    = os.environ.get("GITHUB_REPO", "morganhf6969/mmlnkautoilove")
PENDING_PATH   = "data/pending.json"
FEED_PATH      = "data/iloveabitini_feed.json"

# ── GitHub API ────────────────────────────────────────────────────────────────

def _gh_headers():
    return {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
    }

def _gh_get(path):
    r = requests.get(
        f"https://api.github.com/repos/{GITHUB_REPO}/contents/{path}",
        headers=_gh_headers(),
    )
    if r.status_code == 404:
        return [], ""
    r.raise_for_status()
    data = r.json()
    content = json.loads(base64.b64decode(data["content"]).decode())
    return content.get("items", []), data["sha"]

def _gh_put(path, items, sha, message):
    feed = {
        "version": 1,
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "items": items,
    }
    content_b64 = base64.b64encode(
        json.dumps(feed, ensure_ascii=False, indent=2).encode()
    ).decode()
    payload = {"message": message, "content": content_b64}
    if sha:
        payload["sha"] = sha
    r = requests.put(
        f"https://api.github.com/repos/{GITHUB_REPO}/contents/{path}",
        json=payload,
        headers=_gh_headers(),
    )
    r.raise_for_status()

# ── Scraping con instaloader ──────────────────────────────────────────────────

def scrape_new(existing_urls):
    L = instaloader.Instaloader(
        download_pictures=False,
        download_videos=False,
        download_video_thumbnails=False,
        download_geotags=False,
        download_comments=False,
        save_metadata=False,
        quiet=True,
    )

    try:
        profile = instaloader.Profile.from_username(L.context, TARGET_ACCOUNT)
    except Exception as e:
        log.error("Errore caricamento profilo: %s", e)
        return []

    new = []
    count = 0
    for post in profile.get_posts():
        if count >= MAX_POSTS:
            break
        count += 1

        url = f"https://www.instagram.com/p/{post.shortcode}/"
        if url in existing_urls:
            continue

        og_image = post.url if post.url else None
        og_title = (post.caption or "").strip()[:120] or f"@{TARGET_ACCOUNT}"

        new.append({
            "url": url,
            "platform": "instagram",
            "og_title": og_title,
            "og_image": og_image,
            "created_at": post.date_utc.isoformat(),
        })
        log.info("  + %s", url)

    return new

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    log.info("=== Scraper Termux @%s ===", TARGET_ACCOUNT)

    if not GITHUB_TOKEN:
        log.error("Variabile GITHUB_TOKEN non impostata!")
        sys.exit(1)

    pending_items, pending_sha = _gh_get(PENDING_PATH)
    feed_items, _             = _gh_get(FEED_PATH)

    existing_urls = (
        {i["url"] for i in feed_items} |
        {i["url"] for i in pending_items}
    )
    log.info("URL già noti: %d", len(existing_urls))

    new_posts = scrape_new(existing_urls)

    if not new_posts:
        log.info("Nessun nuovo post.")
        return

    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    updated_pending = new_posts + pending_items
    _gh_put(PENDING_PATH, updated_pending, pending_sha,
            f"🕷️ {len(new_posts)} nuovi post in pending [{ts}]")

    log.info("%d nuovi post aggiunti al pending.", len(new_posts))

if __name__ == "__main__":
    main()
