import urllib.request, json, ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

# Wayback CDX API for play.coinpoker.com
url = 'http://web.archive.org/cdx/search/cdx?url=play.coinpoker.com/*&output=json&limit=100&fl=original,statuscode,mimetype&filter=statuscode:200&collapse=urlkey'

try:
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    resp = urllib.request.urlopen(req, context=ctx, timeout=20)
    data = json.loads(resp.read())
    print(f"Found {len(data)-1} unique URLs:\n")
    for row in data[1:]:
        orig, code, mime = row
        print(f"{code} [{mime[:30]}] {orig}")
except Exception as e:
    print(f"Error: {e}")
