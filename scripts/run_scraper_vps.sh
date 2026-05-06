#!/bin/bash
# run_scraper_vps.sh — Esegue lo scraper e pusha il feed su GitHub
# Installazione: crontab -e → 0 */6 * * * /root/scripts/run_scraper_vps.sh >> /root/scraper.log 2>&1

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION_FILE="$REPO_DIR/scripts/.instagram_session.json"
LOG_PREFIX="[$(date '+%Y-%m-%d %H:%M:%S')]"

cd "$REPO_DIR"

echo "$LOG_PREFIX === Scraper @iloveabitini avviato ==="

# Attiva il virtual environment
source "$REPO_DIR/venv/bin/activate"

# Verifica che la sessione esista
if [ ! -f "$SESSION_FILE" ]; then
    echo "$LOG_PREFIX ERRORE: Sessione Instagram non trovata in $SESSION_FILE"
    echo "$LOG_PREFIX Esegui: python scripts/gen_session.py"
    exit 1
fi

# Esporta la sessione come base64 (formato atteso da scraper.py)
export INSTAGRAM_SESSION
INSTAGRAM_SESSION=$(base64 -w 0 "$SESSION_FILE")

# Esegui lo scraper
echo "$LOG_PREFIX Avvio scraper..."
python scripts/scraper.py

# Controlla se il feed è cambiato
git add data/iloveabitini_feed.json

if git diff --staged --quiet; then
    echo "$LOG_PREFIX Nessun nuovo post — nessun commit."
else
    TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
    git commit -m "🔄 Feed @iloveabitini aggiornato [$TIMESTAMP]"
    git push
    echo "$LOG_PREFIX Feed committato e pushato su GitHub ✓"
fi

echo "$LOG_PREFIX === Fine ==="
