import urllib.request, ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

base = 'https://casino-fe-api.coinpoker.com'
paths = [
    '/', '/api', '/api/v1', '/v1', '/v2', '/api/v2',
    '/health', '/status', '/ping',
    '/docs', '/swagger', '/swagger-ui', '/swagger-ui.html',
    '/openapi.json', '/openapi.yaml', '/api-docs',
    '/graphql', '/api/docs', '/api/health',
    '/api/login', '/api/auth', '/api/user',
    '/api/casino', '/casino', '/games',
    '/api/games', '/lobby',
]

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json, text/html, */*',
}

for path in paths:
    url = base + path
    try:
        req = urllib.request.Request(url, headers=headers)
        resp = urllib.request.urlopen(req, context=ctx, timeout=8)
        code = resp.getcode()
        ctype = resp.headers.get('Content-Type', '')
        body = resp.read(200).decode('utf-8', errors='ignore')
        print(f"{code} {path:35s} | {ctype[:40]} | {body[:60].strip()}")
    except urllib.error.HTTPError as e:
        ctype = e.headers.get('Content-Type', '')
        try:
            body = e.read(100).decode('utf-8', errors='ignore')
        except:
            body = ''
        print(f"{e.code} {path:35s} | {ctype[:40]} | {body[:60].strip()}")
    except Exception as ex:
        print(f"ERR {path:35s} | {str(ex)[:60]}")
