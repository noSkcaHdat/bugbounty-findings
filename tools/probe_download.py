import urllib.request, ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

base = 'https://download.coinpoker.com'
paths = [
    '/en/download', '/download', '/', '/en', '/api',
    '/robots.txt', '/sitemap.xml', '/en/download/windows',
    '/en/download/mac', '/en/download/android', '/en/download/ios',
    '/en/download/linux', '/version', '/latest', '/update',
    '/en/download/desktop', '/files', '/client',
]

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'text/html,application/json,*/*',
}

for path in paths:
    url = base + path
    try:
        req = urllib.request.Request(url, headers=headers)
        resp = urllib.request.urlopen(req, context=ctx, timeout=10)
        code = resp.getcode()
        ctype = resp.headers.get('Content-Type', '')
        loc = resp.geturl()
        body = resp.read(300).decode('utf-8', errors='ignore')
        redirect = f" -> {loc}" if loc != url else ""
        print(f"{code} {path:35s} | {ctype[:35]}{redirect}")
        if 'json' in ctype or '/download' in path:
            print(f"       BODY: {body[:120].strip()}")
    except urllib.error.HTTPError as e:
        ctype = e.headers.get('Content-Type', '')
        loc = e.headers.get('Location', '')
        print(f"{e.code} {path:35s} | {ctype[:35]} {f'-> {loc}' if loc else ''}")
    except Exception as ex:
        print(f"ERR {path:35s} | {str(ex)[:60]}")
