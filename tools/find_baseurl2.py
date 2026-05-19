import re

d = open('/tmp/chunk-LAN6M7UU.js').read()

print("=== _a export candidates ===")
matches = re.findall(r'.{0,30}_a[=,\s].{0,100}', d)
seen = set()
for m in matches[:20]:
    k = m[:40]
    if k not in seen:
        seen.add(k)
        print(m[:180])

print("\n=== SERVER_API_URL / location.origin patterns ===")
patterns = [
    r'location\.origin[^;]{0,80}',
    r'SERVER_API_URL[^;]{0,80}',
    r'serverApiUrl[^;]{0,80}',
    r'window\.__env[^;]{0,80}',
    r'qwBaseUrl[^;]{0,80}',
]
for pat in patterns:
    found = re.findall(pat, d)
    if found:
        print(f"\n{pat}:")
        for f in found[:3]:
            print(f"  {f[:150]}")
