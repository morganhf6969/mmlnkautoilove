#!/usr/bin/env python3
"""
Genera (o rigenera) la sessione Instagram e la salva in scripts/.instagram_session.json
Esegui questo script manualmente ogni volta che la sessione scade.
"""

import json
from pathlib import Path
from instagrapi import Client

SESSION_FILE = Path(__file__).parent / ".instagram_session.json"

def main():
    print("=== Generatore sessione Instagram ===\n")
    username = input("Username Instagram: ").strip()
    password = input("Password Instagram: ").strip()

    cl = Client()
    cl.delay_range = [2, 5]

    print("\nLogin in corso...")
    try:
        cl.login(username, password)
    except Exception as e:
        print(f"\n❌ Errore login: {e}")
        print("Se richiede verifica, completa il challenge e riprova.")
        return

    cl.dump_settings(str(SESSION_FILE))
    print(f"\n✅ Sessione salvata in: {SESSION_FILE}")
    print("Ora puoi eseguire scraper_mac.py normalmente.")

if __name__ == "__main__":
    main()
