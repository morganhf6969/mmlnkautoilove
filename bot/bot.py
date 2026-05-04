#!/usr/bin/env python3
"""
Bot Telegram - MemoLink @iloveabitini
Legge data/pending.json da GitHub, chiede gli hashtag e aggiorna feed.json.
Non fa scraping Instagram — ci pensa il Mac via LaunchAgent.
"""

import base64
import json
import logging
import os
from datetime import datetime, timezone
from typing import Dict, List, Optional

import requests
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

TELEGRAM_TOKEN = os.environ["TELEGRAM_TOKEN"]
ADMIN_CHAT_ID  = int(os.environ["ADMIN_CHAT_ID"])
GITHUB_TOKEN   = os.environ["GITHUB_TOKEN"]
GITHUB_REPO    = os.environ["GITHUB_REPO"]   # "owner/repo"

PENDING_PATH = "data/pending.json"
FEED_PATH    = "data/iloveabitini_feed.json"
POLL_INTERVAL = 10 * 60   # controlla il pending ogni 10 minuti

# ── Stato globale ─────────────────────────────────────────────────────────────

_queue:   List[Dict]    = []
_current: Optional[Dict] = None
_waiting: bool           = False

# ── GitHub API ────────────────────────────────────────────────────────────────

def _gh_headers():
    return {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
    }

def _gh_get(path: str) -> tuple:
    """Restituisce (items, sha)."""
    r = requests.get(
        f"https://api.github.com/repos/{GITHUB_REPO}/contents/{path}",
        headers=_gh_headers(),
    )
    if r.status_code == 404:
        return [], ""
    r.raise_for_status()
    data    = r.json()
    content = json.loads(base64.b64decode(data["content"]).decode())
    return content.get("items", []), data["sha"]

def _gh_put(path: str, items: list, sha: str, message: str):
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

# ── Logica Telegram ───────────────────────────────────────────────────────────

async def _send_next(bot):
    global _current, _waiting, _queue

    if not _queue:
        _current = None
        _waiting = False
        await bot.send_message(ADMIN_CHAT_ID, "✅ Tutti i post in pending sono stati elaborati!")
        return

    _current = _queue.pop(0)
    _waiting = True

    url      = _current["url"]
    caption  = _current.get("og_title", "")
    og_image = _current.get("og_image")

    testo = (
        f"📸 Nuovo post da @iloveabitini\n\n"
        f"🔗 {url}\n\n"
        f"📝 {caption}\n\n"
        f"Inserisci gli hashtag (es: #moda #abitini)\n"
        f"oppure /skip per saltare."
    )

    try:
        if og_image:
            await bot.send_photo(ADMIN_CHAT_ID, photo=og_image, caption=testo)
        else:
            await bot.send_message(ADMIN_CHAT_ID, testo)
    except Exception:
        await bot.send_message(ADMIN_CHAT_ID, testo)


async def _salva_e_avanza(bot, hashtags: str):
    global _current, _waiting

    _current["hashtags"] = hashtags
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

    try:
        # Aggiorna feed.json
        feed_items, feed_sha = _gh_get(FEED_PATH)
        feed_items = [_current] + feed_items
        _gh_put(FEED_PATH, feed_items, feed_sha,
                f"✅ Aggiunto post con hashtag [{ts}]")

        # Rimuovi dal pending.json
        pending_items, pending_sha = _gh_get(PENDING_PATH)
        pending_items = [i for i in pending_items if i["url"] != _current["url"]]
        _gh_put(PENDING_PATH, pending_items, pending_sha,
                f"🗑️ Rimosso da pending [{ts}]")

        log.info("Salvato: %s", _current["url"])
    except Exception as e:
        log.error("Errore GitHub: %s", e)
        await bot.send_message(ADMIN_CHAT_ID, f"⚠️ Errore GitHub: {e}")

    _current = None
    _waiting = False
    await _send_next(bot)

# ── Check pending periodico ───────────────────────────────────────────────────

async def _poll_pending(context: ContextTypes.DEFAULT_TYPE):
    global _queue

    log.info("Controllo pending su GitHub...")
    try:
        pending_items, _ = _gh_get(PENDING_PATH)

        if not pending_items:
            log.info("Nessun post in pending.")
            return

        # Aggiungi solo URL non già in coda o in lavorazione
        known = {i["url"] for i in _queue}
        if _current:
            known.add(_current["url"])

        nuovi = [i for i in pending_items if i["url"] not in known]

        if not nuovi:
            log.info("Nessun nuovo post nel pending.")
            return

        log.info("%d nuovi post trovati nel pending.", len(nuovi))
        _queue.extend(nuovi)

        await context.bot.send_message(
            ADMIN_CHAT_ID,
            f"🆕 {len(nuovi)} nuovi post pronti! Te li mostro uno per uno.",
        )

        if not _waiting:
            await _send_next(context.bot)

    except Exception as e:
        log.error("Errore poll pending: %s", e)

# ── Command handlers ──────────────────────────────────────────────────────────

async def cmd_start(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat.id != ADMIN_CHAT_ID:
        return
    await update.message.reply_text(
        "👋 Bot MemoLink attivo!\n\n"
        "/check — controlla subito il pending\n"
        "/status — quanti post sono in coda\n"
        "/skip — salta il post corrente"
    )

async def cmd_check(update: Update, ctx: ContextTypes.DEFAULT_TYPE):
    if update.effective_chat.id != ADMIN_CHAT_ID:
        return
    await update.message.reply_text("🔍 Controllo pending...")
    await _poll_pending(ctx)

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
    await update.message.reply_text("⏭ Post saltato.")
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
    app = Application.builder().token(TELEGRAM_TOKEN).build()

    app.add_handler(CommandHandler("start",  cmd_start))
    app.add_handler(CommandHandler("check",  cmd_check))
    app.add_handler(CommandHandler("status", cmd_status))
    app.add_handler(CommandHandler("skip",   cmd_skip))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    # Controlla il pending ogni 10 minuti
    app.job_queue.run_repeating(_poll_pending, interval=POLL_INTERVAL, first=15)

    log.info("Bot avviato — polling Telegram + check pending ogni 10 min.")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
