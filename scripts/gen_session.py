from instagrapi import Client

username = input("Username Instagram: ")
password = input("Password Instagram: ")

cl = Client()
cl.login(username, password)
cl.dump_settings("/tmp/instagram_session.json")
print("Sessione salvata in /tmp/instagram_session.json")
