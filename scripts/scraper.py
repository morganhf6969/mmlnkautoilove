#!/usr/bin/env python3
"""
Scraper automatico per @iloveabitini su Instagram.
Recupera tutti i post (video, reel, foto) e aggiorna data/iloveabitini_feed.json
con i nuovi link, senza duplicare quelli già presenti.
"""

import json
import os
import sys
import logging
from datetime import datetime, timezone
from pathlib import Path

from instagrapi import Client
from instagrapi.exceptions import LoginRequired, BadPassword, ChallengeRequired

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

# ─── Configurazione ────────────────────────────────────────────────────────────

TARGET_ACCOUNT = "iloveabitini"
MAX_POSTS = 50          # quanti post recenti controllare ad ogni run
REPO_ROOT = Path(__file__).parent.parent
DATA_FILE = REPO_ROOT / "data" / "iloveabitini_feed.json"
SESSION_FILE = Path(__file__).parent / ".instagram_session.json"

# ─── Feed helpers ──────────────────────────────────────────────────────────────

def load_feed() -> dict:
    if DATA_FILE.exists():
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    return {"version": 1, "last_updated": None, "items": []}


def save_feed(feed: dict, new_count: int = 0):
    DATA_FILE.parent.mkdir(parents=True, exist_ok=True)
    feed["last_updated"] = datetime.now(timezone.utc).isoformat()
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(feed, f, ensure_ascii=False, indent=2)
    log.info("Feed salvato — totale %d elementi (%+d nuovi)", len(feed["items"]), new_count)

# ─── Client Instagram ──────────────────────────────────────────────────────────

def build_client() -> Client:
    session_b64 = os.environ.get("INSTAGRAM_SESSION")
    username = os.environ.get("INSTAGRAM_USERNAME")
    password = os.environ.get("INSTAGRAM_PASSWORD")

    cl = Client()
    cl.delay_range = [2, 5]

    # Modalità preferita: sessione pre-generata (evita il login da IP cloud)
    if session_b64:
        try:
            import base64, json, tempfile
            session_json = base64.b64decode(session_b64).decode("utf-8")
            tmp = tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False)
            tmp.write(session_json)
            tmp.close()
            cl.load_settings(tmp.name)
            # Reuse session senza login completo
            cl.get_timeline_feed()
            log.info("Sessione Instagram ripristinata dal secret.")
            return cl
        except Exception as e:
            log.warning("Sessione dal secret non valida, tento login: %s", e)

    # Fallback: login con username/password
    if not username or not password:
        log.error("Nessuna sessione valida e credenziali mancanti.")
        sys.exit(1)

    try:
        cl.login(username, password)
        cl.dump_settings(SESSION_FILE)
        log.info("Login effettuato e sessione salvata.")
    except BadPassword:
        log.error("Password errata per @%s.", username)
        sys.exit(1)
    except ChallengeRequired:
        log.error("Instagram richiede una verifica. Rigenera la sessione dal Mac.")
        sys.exit(1)
    except Exception as e:
        log.error("Errore di login: %s", e)
        sys.exit(1)

    return cl

# ─── Scraping ─────────────────────────────────────────────────────────────────

def scrape_new_items(cl: Client, existing_urls: set) -> list:
    """Recupera i post di @iloveabitini non ancora presenti nel feed."""
    try:
        user_id = cl.user_id_from_username(TARGET_ACCOUNT)
        log.info("User ID di @%s: %s", TARGET_ACCOUNT, user_id)
    except Exception as e:
        log.error("Impossibile trovare l'utente @%s: %s", TARGET_ACCOUNT, e)
        sys.exit(1)

    try:
        medias = cl.user_medias(user_id, amount=MAX_POSTS)
        log.info("Post recuperati: %d", len(medias))
    except Exception as e:
        log.error("Errore recupero media: %s", e)
        sys.exit(1)

    new_items = []
    for media in medias:
        url = f"https://www.instagram.com/p/{media.code}/"
        if url in existing_urls:
            continue

        # Thumbnail: preferisci thumbnail_url (per video), poi image_url (foto)
        og_image = None
        if media.thumbnail_url:
            og_image = str(media.thumbnail_url)
        elif media.image_versions2 and media.image_versions2.get("candidates"):
            og_image = media.image_versions2["candidates"][0].get("url")

        # Titolo: prime 120 chars della didascalia oppure nome account
        og_title = (media.caption_text or "").strip()[:120] or f"@{TARGET_ACCOUNT}"

        item = {
            "url": url,
            "platform": "instagram",
            "og_title": og_title,
            "og_image": og_image,
            "hashtags": "",
            "created_at": (
                media.taken_at.isoformat()
                if media.taken_at
                else datetime.now(timezone.utc).isoformat()
            ),
        }
        new_items.append(item)
        log.info("  + Nuovo post: %s", url)

    return new_items

# ─── Main ─────────────────────────────────────────────────────────────────────

def main():
    log.info("=== Scraper @%s avviato ===", TARGET_ACCOUNT)

    feed = load_feed()
    existing_urls = {item["url"] for item in feed["items"]}
    log.info("Feed esistente: %d elementi.", len(existing_urls))

    cl = build_client()
    new_items = scrape_new_items(cl, existing_urls)

    if not new_items:
        log.info("Nessun nuovo post trovato.")
        save_feed(feed, new_count=0)
        print("new_items_count=0")
        return

    # Inserisci i nuovi in testa (i più recenti prima)
    feed["items"] = new_items + feed["items"]
    save_feed(feed, new_count=len(new_items))

    print(f"new_items_count={len(new_items)}")
    log.info("=== Completato: %d nuovi post aggiunti ===", len(new_items))


if __name__ == "__main__":
    main()
