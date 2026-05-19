#!/usr/bin/env bash
set -euo pipefail

GOBIN="/home/hackson/go/bin"
TARGET="facturaz.es"
OUT="/mnt/c/Users/karth/bugbounty/recon"

echo "=============================="
echo " FACTURAZ ENUMERATION"
echo "=============================="

# 1. Subdomains
echo ""
echo "[+] Subdomains (subfinder)..."
"$GOBIN/subfinder" -d "$TARGET" -silent 2>/dev/null | tee "$OUT/subdomains/facturaz.es-subs.txt"

SUBS=$(cat "$OUT/subdomains/facturaz.es-subs.txt")

# 2. Live host probing
echo ""
echo "[+] Probing live hosts (httpx)..."
echo "$SUBS" | "$GOBIN/httpx" -silent -status-code -title -tech-detect -follow-redirects \
  -o "$OUT/subdomains/facturaz.es-live.txt" 2>/dev/null
cat "$OUT/subdomains/facturaz.es-live.txt"

# 3. API endpoint probing
echo ""
echo "[+] Probing api.facturaz.es endpoints..."
PATHS=(
  "/" "/v1" "/v2" "/api" "/api/v1" "/api/v2"
  "/public" "/public/v1" "/graphql"
  "/swagger" "/swagger.json" "/swagger/index.html"
  "/openapi.json" "/openapi.yaml" "/api-docs"
  "/docs" "/health" "/status" "/ping" "/debug" "/metrics"
  "/users" "/invoices" "/contacts" "/companies" "/auth"
  "/login" "/token" "/oauth" "/oauth/token"
  "/admin" "/internal" "/private"
  "/.env" "/.git/config" "/backup.zip" "/config.json"
)

for path in "${PATHS[@]}"; do
  result=$(curl -sk -o - -w "HTTPCODE:%{http_code}" "https://api.facturaz.es${path}" 2>/dev/null)
  code=$(echo "$result" | grep -o 'HTTPCODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$result" | sed 's/HTTPCODE:[0-9]*$//' | head -c 120 | tr -d '\n')
  if [[ "$code" != "404" && "$code" != "000" ]]; then
    echo "  [$code] $path => $body"
  fi
done

# 4. Security headers check
echo ""
echo "[+] Security headers — app.facturaz.es..."
curl -sk -I "https://app.facturaz.es/" 2>/dev/null | grep -iE "content-security-policy|x-frame-options|x-xss-protection|strict-transport-security|x-content-type|referrer-policy|permissions-policy|server:|x-powered-by|set-cookie" || echo "  (none interesting)"

echo ""
echo "[+] Security headers — api.facturaz.es..."
curl -sk -I "https://api.facturaz.es/" 2>/dev/null | grep -iE "content-security-policy|x-frame-options|x-xss-protection|strict-transport-security|x-content-type|referrer-policy|permissions-policy|server:|x-powered-by|set-cookie" || echo "  (none interesting)"

# 5. Check for CORS misconfiguration on API
echo ""
echo "[+] CORS test on api.facturaz.es..."
curl -sk -I -H "Origin: https://evil.com" "https://api.facturaz.es/" 2>/dev/null | grep -i "access-control" || echo "  No CORS headers returned"

# 6. Check www for .git exposure
echo ""
echo "[+] Checking for exposed .git on www.facturaz.es..."
code=$(curl -sk -o /dev/null -w "%{http_code}" "https://www.facturaz.es/.git/config" 2>/dev/null)
echo "  /.git/config => HTTP $code"

code2=$(curl -sk -o /dev/null -w "%{http_code}" "https://app.facturaz.es/.git/config" 2>/dev/null)
echo "  app /.git/config => HTTP $code2"

echo ""
echo "[+] Done. Check $OUT for saved output."
