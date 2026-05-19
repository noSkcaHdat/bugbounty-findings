import re

data = open('/tmp/chunk-LAN6M7UU.js').read()

print("=== p0 BASE URL ===")
# p0 is likely assigned as a constant
matches = re.findall(r'(?:p0|const p0|let p0|var p0)\s*[=,]\s*["\']([^"\']{5,120})["\']', data)
for m in matches[:5]:
    print(m)

# Also look for it near window/environment config
matches2 = re.findall(r'.{0,30}p0.{0,80}window\.qw[A-Z].{0,80}', data)
for m in matches2[:3]:
    print(m)

# Find environment/config assignments
matches3 = re.findall(r'window\.[a-zA-Z_]{2,20}\s*=\s*["\'][^"\']{5,100}["\']', data)
for m in matches3[:10]:
    print(m)

print("\n=== CRYPTO/ENCRYPT METHOD ===")
encrypt_matches = re.findall(r'.{0,200}encrypt.{0,200}', data)
seen = set()
for m in encrypt_matches[:10]:
    key = m[:50]
    if key not in seen:
        seen.add(key)
        print(m[:300])
        print("---")

print("\n=== REGISTER ENDPOINT ===")
reg = re.findall(r'.{0,100}register.{0,100}', data)
seen2 = set()
for m in reg[:15]:
    if 'api/' in m.lower() or 'http' in m.lower() or 'post' in m.lower():
        key = m[:60]
        if key not in seen2:
            seen2.add(key)
            print(m[:250])
