import re

html = open('/tmp/www.html').read()

# All hrefs
links = sorted(set(re.findall(r'href=["\']([^"\'> ]+)["\']', html)))
keywords = ['sign', 'trial', 'free', 'register', 'login', 'start', 'pricing',
            'plan', 'account', 'contact', 'demo', 'onboard', 'automation.quickwork']

print("=== SIGNUP/TRIAL/LOGIN LINKS ===")
for l in links:
    if any(k in l.lower() for k in keywords):
        print(l)

print("\n=== ALL UNIQUE HREFS ===")
for l in links:
    print(l)
