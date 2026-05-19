import urllib.request, ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = 'https://casino-fe-api.coinpoker.com/ping'

origins = [
    'https://play.coinpoker.com',
    'https://coinpoker.com',
    'https://www.coinpoker.com',
    'https://evil.coinpoker.com',
    'https://attacker.com',
    'null',
    'https://coinpoker.com.attacker.com',
    'https://notcoinpoker.com',
]

print(f"{'Origin':<40} | {'ACAO':<40} | ACAC | Code")
print('-' * 110)

for origin in origins:
    try:
        req = urllib.request.Request(url)
        req.add_header('Origin', origin)
        req.add_header('User-Agent', 'Mozilla/5.0')
        resp = urllib.request.urlopen(req, context=ctx, timeout=8)
        acao = resp.headers.get('Access-Control-Allow-Origin', '-')
        acac = resp.headers.get('Access-Control-Allow-Credentials', '-')
        print(f"{origin:<40} | {acao:<40} | {acac:<5}| {resp.getcode()}")
    except urllib.error.HTTPError as e:
        acao = e.headers.get('Access-Control-Allow-Origin', '-')
        acac = e.headers.get('Access-Control-Allow-Credentials', '-')
        print(f"{origin:<40} | {acao:<40} | {acac:<5}| {e.code}")
    except Exception as ex:
        print(f"{origin:<40} | ERR: {str(ex)[:50]}")

# Also test OPTIONS preflight
print("\n=== OPTIONS preflight on /ping ===")
try:
    req = urllib.request.Request(url, method='OPTIONS')
    req.add_header('Origin', 'https://play.coinpoker.com')
    req.add_header('Access-Control-Request-Method', 'POST')
    req.add_header('Access-Control-Request-Headers', 'content-type,authorization')
    resp = urllib.request.urlopen(req, context=ctx, timeout=8)
    for h in resp.headers:
        if 'cors' in h.lower() or 'access' in h.lower() or 'allow' in h.lower():
            print(f"  {h}: {resp.headers[h]}")
except Exception as ex:
    print(f"  {ex}")
