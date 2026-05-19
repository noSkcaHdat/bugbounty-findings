import re, glob

data = open('/tmp/chunk-LAN6M7UU.js').read()

# Find login/auth related snippets (100 chars around key terms)
patterns = [
    r'.{0,120}authenticationToken.{0,120}',
    r'.{0,120}passwordEncrypt.{0,120}',
    r'.{0,120}api/authenticate.{0,120}',
    r'.{0,120}register.{0,120}account.{0,120}',
    r'.{0,150}p0\s*[+]\s*["\']api.{0,80}',
    r'.{0,80}baseUrl.{0,80}',
    r'.{0,80}SERVER_API_URL.{0,80}',
    r'.{0,80}apiUrl.{0,80}',
]

for pat in patterns:
    print(f"\n=== {pat[:40]} ===")
    matches = re.findall(pat, data)
    seen = set()
    for m in matches[:5]:
        key = m[:60]
        if key not in seen:
            seen.add(key)
            print(m[:250])
