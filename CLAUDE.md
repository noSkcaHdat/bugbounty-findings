# Bug Bounty Workspace — Hackson Aloysis

You are Claude Code assisting an experienced bug bounty hunter.
Read this entire file before taking any action. This is your full operational context.

---

## Hunter Profile

- **Name**: Hackson Aloysis
- **Handle**: hackson / hacksonaloysis
- **Platform accounts**: Open Bug Bounty (hacksonaloysis), Com Olho (hacksonaloysis), YesWeHack
- **Background**: Security researcher with experience in fintech and data engineering.
- **Prior achievement**: LOA from Latvijas Banka (Latvia's central bank) — LOW severity, August 2025, repec.bank.lv
- **Strengths**: Web app vulnerabilities (XSS, SQLi, IDOR), API security testing, network/infrastructure recon
- **Style**: Verify before submitting. Never report unconfirmed findings. Quality over quantity.

---

## Environment

- **OS**: Windows + WSL (Ubuntu)
- **Base path**: `/mnt/c/Users/karth/bugbounty`
- **Tools**: subfinder v2.14.0, httpx v1.9.0, nuclei v1.1.7 (needs upgrade to v3), ffuf v2.1.0
- **Wordlists**: `~/SecLists` symlinked at `wordlists/seclists`
- **Burp Suite**: Running natively on Windows, proxy through WSL

### Known Tool Issues
- ffuf v2.1.0: use `-s` not `-silent`
- nuclei v1.1.7: outdated, no `-severity` flag. Upgrade: `go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest`

---

## Folder Structure

```
/mnt/c/Users/karth/bugbounty/
├── targets/
├── recon/
│   ├── subdomains/   # <target>-subs.txt, <target>-live.txt, <target>-urls.txt
│   ├── ports/
│   ├── screenshots/
│   ├── endpoints/    # <target>-dirs.json
│   └── vulns/        # <target>-nuclei.txt
├── reports/
│   ├── drafts/
│   ├── submitted/
│   └── acknowledged/ # LOAs live here
├── tools/
│   └── recon.sh
└── wordlists/
    └── seclists -> ~/SecLists
```

---

## Key Commands

```bash
# Subdomain enum
subfinder -d target.com -silent -o recon/subdomains/target-subs.txt

# Probe live hosts
httpx -l recon/subdomains/target-subs.txt -silent -status-code -title -tech-detect -o recon/subdomains/target-live.txt

# Directory fuzz (correct v2.1.0 flag)
ffuf -u https://target.com/FUZZ -w ~/SecLists/Discovery/Web-Content/common.txt -mc 200,301,302,403 -s -rate 10

# API endpoint fuzz
ffuf -u https://target.com/FUZZ -w ~/SecLists/Discovery/Web-Content/api/objects.txt -s -rate 10

# Parameter fuzz
ffuf -u "https://target.com/page?FUZZ=test" -w ~/SecLists/Discovery/Web-Content/burp-parameter-names.txt -s -rate 10

# Check unauthenticated API access
curl -s -w "\nHTTP: %{http_code}" https://api.target.com/v1/endpoint
```

---

## ACTIVE TARGET: Quickwork Bug Bounty Program

### Program Details
- **Platform**: Com Olho (cyber.comolho.com)
- **Company**: Quickwork Technologies Private Limited
- **Website**: https://www.quickwork.co
- **Program type**: Private (access granted after KYC)
- **Launched**: June 26, 2025
- **Total submissions**: 190 (VERY LOW competition)
- **Submission rate**: 0.68%
- **Status**: Ongoing ✅

### Rewards
| Severity | Reward (INR) |
|---|---|
| P1 Critical | ₹15,000 – ₹25,000 |
| P2 Severe | ₹10,000 – ₹15,000 |
| P3 Moderate | ₹5,000 – ₹10,000 |
| P4 Low | ₹1,000 – ₹5,000 |
| P5 Informational | Certificate of Appreciation |

### In-Scope Targets
| Target | URL | Type | Priority |
|---|---|---|---|
| sc-auth | sc-auth.quickwork.co | API | 🔥 HIGH |
| tenants | tenants.quickwork.co | API | 🔥 HIGH |
| automation | automation.quickwork.co | Web | HIGH |
| otc-de-apim | otc-de-apim.quickwork.co | Web | MEDIUM |
| otc-de-automation | otc-de-automation.quickwork.co | Web | MEDIUM |
| jp-automation | jp-automation.quickwork.co | Web | LOW |
| jp-ssl-proxy | jp-ssl-proxy.quickwork.co | Web | LOW |
| ssl-proxy | ssl-proxy.quickwork.co | Web | MEDIUM |
| www | www.quickwork.co | Web | LOW |

### Out-of-Scope (DO NOT TEST)
chat-prod, chat, docs.chat, docs, get, images, lupincmo,
messenger-fileupload, metrics, registry, ssl-proxy-stage,
status, support, tenants-staging, trust, website-staging

### Critical Program Rules
1. No automated tools causing excessive traffic — always add `-rate 10` to ffuf
2. Regional domains are duplicates — bug on automation = do NOT submit same bug for jp-automation
3. /public paths are explicitly OOS
4. No CSP/iframe headers findings unless working PoC without proxy
5. No UI config/version disclosures
6. Submit one report at a time, wait for response before next

### What Quickwork Does
API automation/workflow platform (like Zapier/Make). Users connect apps via APIs and build automated workflows. Attack surface includes:
- OAuth integrations with dozens of third-party services
- Webhook handling and delivery
- API credential storage per tenant
- Multi-tenant workflow isolation
- Complex authorization between tenant accounts

---

## Hunting Plan — Execute in This Order

### Phase 1: Passive Recon (do this first)
```bash
cd /mnt/c/Users/karth/bugbounty

# Probe all in-scope targets
httpx -l <(echo -e "automation.quickwork.co\nsc-auth.quickwork.co\ntenants.quickwork.co\notc-de-apim.quickwork.co\nssl-proxy.quickwork.co\nwww.quickwork.co\njp-automation.quickwork.co\njp-ssl-proxy.quickwork.co\notc-de-automation.quickwork.co") \
  -silent -status-code -title -tech-detect \
  -o recon/subdomains/quickwork-live.txt

cat recon/subdomains/quickwork-live.txt
```

### Phase 2: Unauthenticated API Testing
```bash
# sc-auth — authentication service
curl -s -w "\nHTTP: %{http_code}" https://sc-auth.quickwork.co/
curl -s -w "\nHTTP: %{http_code}" https://sc-auth.quickwork.co/api/
curl -s -w "\nHTTP: %{http_code}" https://sc-auth.quickwork.co/health
curl -s -w "\nHTTP: %{http_code}" https://sc-auth.quickwork.co/api/v1/users
curl -s -w "\nHTTP: %{http_code}" https://sc-auth.quickwork.co/api/v1/sessions
curl -s -w "\nHTTP: %{http_code}" https://sc-auth.quickwork.co/api/v1/tokens

# tenants API
curl -s -w "\nHTTP: %{http_code}" https://tenants.quickwork.co/
curl -s -w "\nHTTP: %{http_code}" https://tenants.quickwork.co/api/
curl -s -w "\nHTTP: %{http_code}" https://tenants.quickwork.co/api/v1/tenants
curl -s -w "\nHTTP: %{http_code}" https://tenants.quickwork.co/api/v1/users

# otc-de-apim — API management, may expose API catalog
curl -s -w "\nHTTP: %{http_code}" https://otc-de-apim.quickwork.co/
curl -s -w "\nHTTP: %{http_code}" https://otc-de-apim.quickwork.co/swagger
curl -s -w "\nHTTP: %{http_code}" https://otc-de-apim.quickwork.co/swagger.json
curl -s -w "\nHTTP: %{http_code}" https://otc-de-apim.quickwork.co/openapi.json
curl -s -w "\nHTTP: %{http_code}" https://otc-de-apim.quickwork.co/api-docs

# ssl-proxy — check for SSRF
curl -s -w "\nHTTP: %{http_code}" https://ssl-proxy.quickwork.co/
```

### Phase 3: Rate-Limited Endpoint Fuzzing
```bash
# API paths on sc-auth (max 10 req/sec)
ffuf -u https://sc-auth.quickwork.co/FUZZ \
  -w ~/SecLists/Discovery/Web-Content/api/objects.txt \
  -mc 200,201,301,302,401,403 \
  -rate 10 -s \
  -o recon/endpoints/sc-auth-dirs.json -of json

# API paths on tenants
ffuf -u https://tenants.quickwork.co/FUZZ \
  -w ~/SecLists/Discovery/Web-Content/api/objects.txt \
  -mc 200,201,301,302,401,403 \
  -rate 10 -s \
  -o recon/endpoints/tenants-dirs.json -of json
```

### Phase 4: Register Account + Get Auth Token
1. Open `https://automation.quickwork.co` in browser
2. Register with real email
3. Open DevTools → Network tab
4. Log in and find any API request to sc-auth or tenants
5. Copy the `Authorization: Bearer <token>` header value
6. Save token: `echo "Bearer eyJ..." > /tmp/qw_token.txt`

### Phase 5: Authenticated API Testing
```bash
TOKEN=$(cat /tmp/qw_token.txt)

# Test sc-auth with token
curl -s -H "Authorization: $TOKEN" https://sc-auth.quickwork.co/api/v1/users
curl -s -H "Authorization: $TOKEN" https://sc-auth.quickwork.co/api/v1/me
curl -s -H "Authorization: $TOKEN" https://sc-auth.quickwork.co/api/v1/sessions

# Test tenants API with token
curl -s -H "Authorization: $TOKEN" https://tenants.quickwork.co/api/v1/tenants
curl -s -H "Authorization: $TOKEN" https://tenants.quickwork.co/api/v1/users
curl -s -H "Authorization: $TOKEN" https://tenants.quickwork.co/api/v1/me
```

### Phase 6: IDOR Testing (Requires 2 Accounts)
1. Register Account A → create a workflow → note workflow ID from URL
2. Register Account B with different email → get its token
3. Use Account B token to access Account A's workflow ID
4. Test all resource types: workflows, integrations, webhooks, connections

```bash
# With Account B token, try accessing Account A resources
TOKEN_B=$(cat /tmp/qw_token_b.txt)
WORKFLOW_ID_A="id_from_account_a"

curl -s -H "Authorization: $TOKEN_B" \
  https://automation.quickwork.co/api/v1/workflows/$WORKFLOW_ID_A
```

### Phase 7: XSS Testing in App
Test these fields in Burp Suite with payload `"><img src=x onerror=alert(document.domain)>`:
- Workflow name
- Workflow description
- Trigger name/configuration
- Action configuration fields
- Integration/connection names
- Webhook URLs (if rendered back)

### Phase 8: Webhook SSRF Testing
If the app allows setting webhook URLs for workflow triggers:
```
# Try internal addresses as webhook URL
http://169.254.169.254/latest/meta-data/  (AWS metadata)
http://localhost:8080
http://internal-service/
```

---

## Manual Test Checklist

### Unauthenticated Tests
- [ ] What do sc-auth and tenants return without auth?
- [ ] Any API endpoints accessible without token?
- [ ] Does otc-de-apim expose swagger/openapi docs?
- [ ] What does ssl-proxy reveal at root?
- [ ] Version numbers in response headers?

### Authenticated Tests (after account creation)
- [ ] Capture Bearer token from DevTools
- [ ] Token works on sc-auth and tenants APIs?
- [ ] Any endpoints return more data than expected?
- [ ] Pagination params expose other tenants' data?
- [ ] Create workflow → IDOR test with second account
- [ ] XSS in all input fields
- [ ] Webhook URL SSRF
- [ ] OAuth app connection → open redirect?

### Business Logic (Quickwork-specific)
- [ ] Can Account B execute Account A's workflow?
- [ ] Can Account B access Account A's connected app credentials?
- [ ] Can Account B modify Account A's webhook endpoints?
- [ ] Can you enumerate tenant IDs via API?
- [ ] Rate limiting on workflow execution endpoint?
- [ ] Can you trigger another user's workflow via direct API call?

---

## Vulnerability Report Template

```markdown
**Title**: [Vulnerability Type] on [Affected URL]
**Severity**: P1/P2/P3/P4/P5
**CWE**: [CWE number if known]

**Summary**:
[One paragraph — what it is, where it exists, what an attacker can do]

**Steps to Reproduce**:
1. Navigate to [URL]
2. [Action]
3. [Observed result]

**Impact**:
[Real-world consequence — be specific about data exposed or actions possible]

**Proof of Concept**:
[curl commands, screenshots, request/response pairs]
[NEVER include real user data or tokens]

**Affected URLs**:
- [URL 1]
- [URL 2]

**Suggested Remediation**:
[Practical fix — shows you understand the root cause]

**References**:
- [OWASP link]
- [CVE if relevant]
```

---

## Lessons Learned — Do Not Repeat

1. **Verify end-to-end before submitting** — Facturaz OAuth looked like HIGH but was mitigated
2. **Token in URL fragment is NOT a bug if URL clears instantly** — check `window.location.hash` and browser history
3. **Homelab targets waste time** — move on quickly from personal sites
4. **B2B platforms need company accounts** — verify registration is possible before investing recon time
5. **Regional domain duplicates on Quickwork** — automation finding = don't submit same for jp-automation
6. **ffuf `-silent` is `-s` in v2.1.0**
7. **Nuclei v1.1.7 broken for modern flags** — upgrade before using
8. **OOS list matters** — tenants-staging is OOS even though tenants is in scope

---

## Past Targets Reference

### Getmomo (PAUSED — needs company account)
- Scope: getmomo.de, getmomo.app, getmomo.net
- 33 subdomains mapped
- Key finding: staging.getmomo.de WordPress user enum (OOS standalone)
- API: api.getmomo.app/public/v1 — fully authenticated, no bypass
- Tech: Node.js, Cloudflare, Google Cloud, Swan BaaS
- Resume when: company account available

### Facturaz (PAUSED — findings not confirmed)
- Scope: *.facturaz.es
- Stack: Supabase (GoTrue auth, PostgREST, Storage)
- OAuth open redirect: tested, mitigated by Supabase state validation
- Token in URL: clears instantly, not a finding
- Next: IDOR testing with 2 accounts, XSS in invoice fields

---

## LOA History

| Organization | Severity | Date | Domain | Platform |
|---|---|---|---|---|
| Latvijas Banka | LOW | August 2025 | repec.bank.lv | Direct email |

**Goal**: First paid bounty on Com Olho. First ₹ in the account.

---

## Claude Code — Specific Instructions

1. Always check program rules before suggesting any test
2. Never suggest tests causing DoS or excessive traffic
3. Always add `-rate 10` to ffuf commands for Quickwork
4. Prioritize sc-auth and tenants APIs — highest value
5. When writing curl commands, show expected response codes
6. When a finding is identified — help write complete report using template above
7. Always suggest end-to-end verification before submitting
8. For IDOR — always remind: need two separate accounts
9. Quickwork requires PoC without proxy interceptor for some vuln types — verify this
10. Update this file as findings progress — add confirmed findings to a new section

### Start Here Right Now
Run Phase 1 httpx probe → analyze results → proceed to Phase 2 unauthenticated tests → report back findings.s