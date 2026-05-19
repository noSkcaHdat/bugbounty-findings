#!/usr/bin/env bash
# ffuf directory fuzzing on api.facturaz.es

echo "[+] ffuf on api.facturaz.es — discovering paths..."

/home/hackson/go/bin/ffuf \
  -u "https://api.facturaz.es/FUZZ" \
  -w ~/SecLists/Discovery/Web-Content/common.txt \
  -mc 200,201,204,301,302,303,400,401,403 \
  -fc 404 \
  -s \
  -t 30 \
  -timeout 10 \
  2>/dev/null

echo ""
echo "[+] ffuf on api.facturaz.es /rest/v1/FUZZ — table enumeration..."
/home/hackson/go/bin/ffuf \
  -u "https://api.facturaz.es/rest/v1/FUZZ" \
  -w ~/SecLists/Discovery/Web-Content/api/objects.txt \
  -mc 200,201,204,400,401,403 \
  -fc 404 \
  -s \
  -t 20 \
  -timeout 10 \
  2>/dev/null
