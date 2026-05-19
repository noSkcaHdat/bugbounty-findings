import urllib.request, ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

base = 'https://casino-fe-api.coinpoker.com'
paths = [
    '/ping', '/version', '/info', '/config',
    '/api/config', '/api/version', '/api/info',
    '/api/casino/config', '/api/casino/games',
    '/api/casino/lobby', '/api/casino/categories',
    '/api/casino/providers', '/api/casino/search',
    '/api/user/balance', '/api/user/profile',
    '/api/auth/login', '/api/auth/register',
    '/api/auth/token', '/api/token',
    '/api/wallet', '/api/wallet/balance',
    '/api/bonus', '/api/promotions',
    '/api/jackpot', '/api/tournaments',
    '/metrics', '/actuator', '/actuator/health',
    '/admin', '/admin/api',
]

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    'Accept': 'application/json',
    'Origin': 'https://play.coinpoker.com',
    'Referer': 'https://play.coinpoker.com/',
}

for path in paths:
    url = base + path
    try:
        req = urllib.request.Request(url, headers=headers)
        resp = urllib.request.urlopen(req, context=ctx, timeout=8)
        code = resp.getcode()
        ctype = resp.headers.get('Content-Type', '')
        cors = resp.headers.get('Access-Control-Allow-Origin', '')
        body = resp.read(200).decode('utf-8', errors='ignore')
        print(f"{code} {path:40s} | {ctype[:30]} | CORS:{cors[:30]} | {body[:80].strip()}")
    except urllib.error.HTTPError as e:
        ctype = e.headers.get('Content-Type', '')
        cors = e.headers.get('Access-Control-Allow-Origin', '')
        try:
            body = e.read(100).decode('utf-8', errors='ignore')
        except:
            body = ''
        print(f"{e.code} {path:40s} | {ctype[:30]} | CORS:{cors[:30]} | {body[:80].strip()}")
    except Exception as ex:
        print(f"ERR {path:40s} | {str(ex)[:60]}")
