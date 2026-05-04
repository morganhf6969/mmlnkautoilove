#!/usr/bin/env python3
"""
Bot Telegram - MemoLink @iloveabitini
Controlla ogni 6 ore i nuovi post, chiede gli hashtag e aggiorna il feed su GitHub.
"""

import asyncio
import base64
import json
import logging
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional

import requests
from instagrapi import Client
from instagrapi.exceptions import LoginRequired
from telegram import Update
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

# ── Logging ───────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)

# ── Configurazione ────────────────────────────────────────────────────────────

TELEGRAM_TOKEN    = os.environ["TELEGRAM_TOKEN"]
ADMIN_CHAT_ID     = int(os.environ["ADMIN_CHAT_ID"])
GITHUB_TOKEN      = os.environ["GITHUB_TOKEN"]
GITHUB_REPO       = os.environ["GITHUB_REPO"]          # "owner/repo"
INSTAGRAM_SESSION = os.environ["INSTAGRAM_SESSION"]     # base64

TARGET_ACCOUNT    = "iloveabitini"
MAX_POSTS         = 50
CHECK_INTERVAL    = 6 * 3600                            # secondi
FEED_PATH         = "data/iloveabitini_feed.json"
PENDING_FILE      = Path("pending.json")                # persistenza locale

# ── Stato globale (bot mono-utente) ───────────────────────────────────────────

_queue:   List[Dict]      = []    # post in attesa di hashtag
_current: Optional[Dict]  = None  # post che stiamo gestendo ora
_waiting: bool            = False # aspettiamo risposta dell'admin?

# ── Persistenza locale ────────────────────────────────────────────────────────

def _load_pending() -> list[dict]:
    if PENDING_FILE.exists():
        try:
            return json.loads(PENDING_FILE.read_text())
        except Exception:
            return []
    return []

def _save_pending():
    data = ([_current] if _current else []) + _queue
    PENDING_FILE.write_text(json.dumps(data, ensure_ascii=False, indent=2))

# ── Instagram ─────────────────────────────────────────────────────────────────

def _instagram_client() -> Client:
    session_data = json.loads(base64.b64decode(INSTAGRAM_SESSION).decode())
    cl = Client()
    cl.delay_range = [2, 5]
    cl.set_settings(session_data)
    cl.get_timeline_feed()   # verifica che la sessione sia valida
    return cl

def _scrape_new(existing_urls: set) -> list[dict]:
    cl = _instagram_client()
    user_id = cl.user_info_by_username_v1(TARGET_ACCOUNT).pk
    medias = cl.user_medias(user_id, amount=MAX_POSTS)

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
            "hashtags": "",
            "created_at": (
                m.taken_at.isoformat() if m.taken_at
                else datetime.now(timezone.utc).isoformat()
            ),
        })
    return new

# ── GitHub API ────────────────────────────────────────────────────────────────

def _github_headers():
    return {"Authorization": f"token {GITHUB_TOKEN}", "Accept": "application/vnd.github.v3+json"}

def _get_feed() -> tuple[list[dict], str]:
    """Restituisce (items, sha_corrente)."""
    r = requests.get(
        f"https://api.github.com/repos/{GITHUB_REPO}/contents/{FEED_PATH}",
        headers=_github_headers(),
    )
    if r.status_code == 404:
        return [], ""
    r.raise_for_status()
    data = r.json()
    content = base64.b64decode(data["content"]).decode()
    feed = json.loads(content)
    return feed.get("items", []), data["sha"]

def _commit_feed(items: list[dict], sha: str):
    feed = {
        "version": 1,
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "items": items,
    }
    content_b64 = base64.b64encode(
        json.dumps(feed, ensure_ascii=False, indent=2).encode()
    ).decode()
    payload = {
        "message": f"🔄 Feed aggiornato [{datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}]",
        "content": content_b64,
        "sha": sha,
    }
    if not sha:
        payload.pop("sha")
    r = requests.put(
        f"https://api.github.com/repos/{GITHUB_REPO}/contents/{FEED_PATH}",
        json=payload,
        headers=_github_headers(),
    )
    r.raise_for_status()

# ── Logica Telegram ───────────────────────────────────────────────────────────

async def _send_next(bot):
    """Invia il prossimo post dalla coda."""
    global _current, _waiting, _queue

    if not _queue:
        _current = None
        _waiting = False
        await bot.send_message(ADMIN_CHAT_ID, "✅ Tutti i nuovi post sono stati elaborati!")
        return

    _current = _queue.pop(0)
    _waiting = True
    _save_pending()

    url      = _current["url"]
    caption  = _current.get("og_title", "")
    og_image = _current.get("og_image")

    testo = (
        f"📸 *Nuovo post da @{TARGET_ACCOUNT}*\n\n"
        f"🔗 {url}\n\n"
        f"📝 _{caption}_\n\n"
        f"Inserisci gli hashtag \\(es\\: \\#moda \\#abitini\\)\n"
        f"oppure /skip per saltare\\."
    )

    try:
        if og_image:
            await bot.send_photo(
                ADMIN_CHAT_ID,
                photo=og_image,
                caption=testo,
                parse_mode="MarkdownV2",
            )
        else:
            await bot.send_message(ADMIN_CHAT_ID, testo, parse_mode="MarkdownV2")
    except Exception:
        # Fallback senza markdown se la photo o il parsing fallisce
        await bot.send_message(
            ADMIN_CHAT_ID,
            f"📸 Nuovo post: {url}\n\n{caption}\n\nInserisci gli hashtag o /skip:",
        )


async def _salva_e_avanza(bot, hashtags: str):
    """Salva il post corrente con gli hashtag e passa al prossimo."""
    global _current, _waiting

    _current["hashtags"] = hashtags

    try:
        items, sha = _get_feed()
        items = [_current] + items   # più recente in testa
        _commit_feed(items, sha)
        log.info("Aggiornato GitHub: %s", _current["url"])
    except Exception as e:
        log.error("Errore GitHub: %s", e)
        await bot.send_message(ADMIN_CHAT_ID, f"⚠️ Errore GitHub: {e}")

    _current = None
    _waiting = False
    _save_pending()
    await _send_next(bot)

# ── Check periodico ───────────────────────────────────────────────────────────

async def _check(context: ContextTypes.DEFAULT_TYPE):
    """Chiamato ogni 6 ore dal job_queue e dal comando /check."""
    global _queue

    log.info("Controllo nuovi post @%s...", TARGET_ACCOUNT)
    bot = context.bot

    try:
        items, _ = _get_feed()
        existing = {i["url"] for i in items}
        for p in ([_current] if _current else []) + _queue:
            existing.add(p["url"])

        new_posts = _scrape_new(existing)

        if not new_posts:
            log.info("Nessun nuovo post.")
            return

        log.info("%d nuovi post trovati.", len(new_posts))
        _queue.extend(new_posts)
        _save_pending()

        await bot.send_message(
            ADMIN_CHAT_ID,
            f"🆕 {len(new_posts)} nuovi post da @{TARGET_ACCOUNT}! Te li mostro uno per uno.",
        )

        if not _waiting:
            await _send_next(bot)

    except LoginRequired:
        await bot.send_message(ADMIN_CHAT_ID, "⚠️ Sessione Instagram scaduta. Rigenera il secret INSTAGRAM_SESSION.")
    except Exception as e:
        log.error("Errore check: %s", e)
        await bot.send_message(ADMIN_CHAT_ID, f"⚠️ Errore: {e}")

# ── Command handlers ──────────────────────────────────────────────────────────

async def cmd_start(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat.id != ADMIN_CHAT_ID:
        return
    await update.message.reply_text(
        "👋 Bot MemoLink attivo!\n\n"
        "/check — controlla subito nuovi post\n"
        "/status — quanti post sono in coda\n"
        "/skip — salta il post corrente senza hashtag"
    )

async def cmd_check(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat.id != ADMIN_CHAT_ID:
        return
    await update.message.reply_text("🔍 Controllo in corso…")
    await _check(ctx)

async def cmd_status(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat.id != ADMIN_CHAT_ID:
        return
    n = len(_queue) + (1 if _current else 0)
    await update.message.reply_text(f"📊 Post in attesa di hashtag: {n}")

async def cmd_skip(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat.id != ADMIN_CHAT_ID:
        return
    if not _waiting or not _current:
        await update.message.reply_text("Nessun post in attesa.")
        return
    await update.message.reply_text("⏭ Post saltato (salvato senza hashtag).")
    await _salva_e_avanza(ctx.bot, "")

async def handle_text(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat.id != ADMIN_CHAT_ID:
        return
    if not _waiting:
        await update.message.reply_text("Nessun post in attesa. Usa /check.")
        return
    hashtags = update.message.text.strip()
    await update.message.reply_text(f"✅ Salvato con hashtag: {hashtags}")
    await _salva_e_avanza(ctx.bot, hashtags)

# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    global _queue, _current, _waiting

    # Ripristina coda da file locale (dopo un riavvio)
    pending = _load_pending()
    if pending:
        _current = pending[0]
        _queue   = pending[1:]
        _waiting = True
        log.info("Ripristinati %d post in pending.", len(pending))

    app = Application.builder().token(TELEGRAM_TOKEN).build()

    # Handlers
    app.add_handler(CommandHandler("start",  cmd_start))
    app.add_handler(CommandHandler("check",  cmd_check))
    app.add_handler(CommandHandler("status", cmd_status))
    app.add_handler(CommandHandler("skip",   cmd_skip))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    # Check ogni 6 ore (primo check dopo 30 secondi dall'avvio)
    app.job_queue.run_repeating(_check, interval=CHECK_INTERVAL, first=30)

    log.info("Bot avviato.")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
