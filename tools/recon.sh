#!/bin/bash

# ─────────────────────────────────────────────
#  recon.sh — Hackson's Bug Bounty Recon Script
#  Usage: ./recon.sh <target-domain>
#  Example: ./recon.sh example.gov
# ─────────────────────────────────────────────

TARGET=$1
BASE="/mnt/c/Users/karth/bugbounty"
OUT="$BASE/recon"
DATE=$(date +%Y-%m-%d)

if [ -z "$TARGET" ]; then
  echo "[!] Usage: ./recon.sh <target-domain>"
  exit 1
fi

mkdir -p "$OUT/subdomains" "$OUT/ports" "$OUT/screenshots" "$OUT/endpoints" "$OUT/vulns"

echo ""
echo "════════════════════════════════════════"
echo "  TARGET : $TARGET"
echo "  DATE   : $DATE"
echo "  OUTPUT : $OUT"
echo "════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────
# STEP 1 — Subdomain Enumeration
# ─────────────────────────────────────────────
echo "[1/5] Running subfinder..."
subfinder -d "$TARGET" -silent -o "$OUT/subdomains/$TARGET-subs.txt"
SUB_COUNT=$(wc -l < "$OUT/subdomains/$TARGET-subs.txt")
echo "      Found $SUB_COUNT subdomains → $OUT/subdomains/$TARGET-subs.txt"

# ─────────────────────────────────────────────
# STEP 2 — Probe Live Hosts
# ─────────────────────────────────────────────
echo ""
echo "[2/5] Probing live hosts with httpx..."
httpx -l "$OUT/subdomains/$TARGET-subs.txt" \
  -silent \
  -status-code \
  -title \
  -tech-detect \
  -o "$OUT/subdomains/$TARGET-live.txt"
LIVE_COUNT=$(wc -l < "$OUT/subdomains/$TARGET-live.txt")
echo "      $LIVE_COUNT live hosts → $OUT/subdomains/$TARGET-live.txt"

# ─────────────────────────────────────────────
# STEP 3 — Extract live URLs only
# ─────────────────────────────────────────────
echo ""
echo "[3/5] Extracting clean URLs..."
awk '{print $1}' "$OUT/subdomains/$TARGET-live.txt" > "$OUT/subdomains/$TARGET-urls.txt"
echo "      Clean URL list → $OUT/subdomains/$TARGET-urls.txt"

# ─────────────────────────────────────────────
# STEP 4 — Directory Fuzzing on main target
# ─────────────────────────────────────────────
echo ""
echo "[4/5] Fuzzing directories on https://$TARGET ..."
ffuf -u "https://$TARGET/FUZZ" \
  -w "$BASE/wordlists/seclists/Discovery/Web-Content/common.txt" \
  -mc 200,301,302,403 \
  -silent \
  -o "$OUT/endpoints/$TARGET-dirs.json" \
  -of json
echo "      Results → $OUT/endpoints/$TARGET-dirs.json"

# ─────────────────────────────────────────────
# STEP 5 — Nuclei Vulnerability Scan
# ─────────────────────────────────────────────
echo ""
echo "[5/5] Running nuclei on live hosts..."
nuclei -l "$OUT/subdomains/$TARGET-urls.txt" \
  -severity low,medium,high,critical \
  -silent \
  -o "$OUT/vulns/$TARGET-nuclei.txt"
VULN_COUNT=$(wc -l < "$OUT/vulns/$TARGET-nuclei.txt" 2>/dev/null || echo 0)
echo "      $VULN_COUNT findings → $OUT/vulns/$TARGET-nuclei.txt"

# ─────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════"
echo "  RECON COMPLETE — $TARGET"
echo "────────────────────────────────────────"
echo "  Subdomains  : $SUB_COUNT"
echo "  Live hosts  : $LIVE_COUNT"
echo "  Nuclei hits : $VULN_COUNT"
echo "════════════════════════════════════════"
echo ""
echo "  Next steps:"
echo "  → Review $OUT/subdomains/$TARGET-live.txt"
echo "  → Check $OUT/vulns/$TARGET-nuclei.txt"
echo "  → Open interesting hosts in Burp Suite"
echo ""
