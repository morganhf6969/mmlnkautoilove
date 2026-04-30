import instaloader
import json

USERNAME_CANALE = "iloveabitini"   # profilo da cui estrarre i video

TUO_USERNAME = "il_tuo_account"    # <-- il tuo username Instagram
TUA_PASSWORD = "la_tua_password"   # <-- la tua password Instagram

L = instaloader.Instaloader(
    sleep=True,
    quiet=False,
    user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15"
)
try:
    L.login("app_memolink", "fV3LpKJ@97s.!Sz")
    print("Login effettuato con successo!")
except Exception as e:
    print(f"Errore login: {e}")
    exit(1)

try:
    profile = instaloader.Profile.from_username(L.context, USERNAME_CANALE)
    print(f"Profilo trovato: {profile.username} ({profile.mediacount} post)")
except Exception as e:
    print(f"Errore profilo: {e}")
    exit(1)

links = []
for post in profile.get_posts():
    if post.is_video:
        links.append({
            "url": f"https://www.instagram.com/p/{post.shortcode}/",
            "title": post.caption[:80] if post.caption else "",
            "date": str(post.date)
        })
        print(f"Trovato: {post.shortcode}")

with open("video_links.json", "w", encoding="utf-8") as f:
    json.dump(links, f, indent=2, ensure_ascii=False)

print(f"\nTotale video trovati: {len(links)}")
print("Salvato in video_links.json")
