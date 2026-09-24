# Setup — run locally without a tenant

Everything in this repo is designed for **offline / local demos**. You do not need Microsoft Entra, Prometheus, or a webhook receiver to exercise the scripts and talk through the runbooks in an interview.

> Do not commit tenant IDs, secrets, certificates, or real ticket exports.

---

## 1. Prerequisites

| Tool | Needed for | Notes |
|------|------------|-------|
| bash + `curl` | `scripts/check-service-health.sh` | Standard on Linux, macOS, WSL |
| PowerShell 7 (`pwsh`) or Windows PowerShell 5.1+ | `*.ps1` scripts | Cross-platform PS7 preferred |
| Optional: Microsoft Graph PowerShell SDK | Only if you opt out of dry-run on `revoke-session-stub.ps1` | See §4 — leave dry-run for portfolio demos |

Clone or copy the repo:

```bash
git clone https://github.com/SudoShad/monitoring-breakglass-ops.git
cd monitoring-breakglass-ops
```

On Windows without Git Bash, open the folder in PowerShell and skip the `.sh` probe (use the `.ps1` health script instead).

---

## 2. Quick verification (no network to identity providers)

```bash
# Shell health probe against a public site (or any host you own)
./scripts/check-service-health.sh --url https://example.com --timeout 5
echo "exit=$?"

# PowerShell alert parser against committed example JSON
pwsh ./scripts/parse-alert.ps1 -Path ./examples/sample-alert-p1.json

# Mock break-glass ticket (writes under ./out/ which is gitignored)
pwsh ./scripts/breakglass-request.ps1 \
  -Requester 'jdoe' \
  -Reason 'P1 — restore read-only reporting access' \
  -DurationMinutes 60 \
  -Approver 'asmith'

# Revoke stub — dry-run / WhatIf only
pwsh ./scripts/revoke-session-stub.ps1 -UserPrincipalName 'jdoe@contoso.example' -WhatIf
```

Parser / syntax smoke (no live calls):

```powershell
pwsh ./tests/Smoke-Syntax.ps1
```

---

## 3. PowerShell health probe

Same intent as the bash script:

```powershell
pwsh ./scripts/check-service-health.ps1 -Uri 'https://example.com' -TimeoutSec 5
pwsh ./scripts/check-service-health.ps1 -ComputerName 'example.com' -Port 443 -TimeoutSec 5
```

Exit codes: `0` healthy, `1` unhealthy / unreachable, `2` bad usage.

---

## 4. Optional: leave dry-run on revoke (recommended)

`revoke-session-stub.ps1` documents the Graph pattern used in the companion [helpdesk-graph-toolkit](https://github.com/SudoShad/helpdesk-graph-toolkit) `Revoke-UserSessions.ps1`.

| Mode | Behavior |
|------|----------|
| Default / `-WhatIf` | Prints the intended Graph call; **no network** |
| `-Execute` + Graph modules + app auth | Would call revoke — **lab tenant only**, same safety rules as the helpdesk toolkit |

For portfolio and interview demos, stay on `-WhatIf`. If you later wire a lab tenant, follow `helpdesk-graph-toolkit` `docs/SETUP.md` for app registration and store credentials **outside** this repo.

---

## 5. Output directory

Mock tickets and optional logs write under `./out/`. That path is gitignored (except `out/README.md`) so accidental PII does not land in commits.

---

## 6. What you still do not need

- A Prometheus / Grafana / PagerDuty account  
- A real break-glass account or privileged identity  
- Entra Privileged Identity Management (PIM) — the docs describe the *pattern*; scripts mock the ticket  

Read [`RUNBOOK.md`](RUNBOOK.md) and [`BREAK-GLASS.md`](BREAK-GLASS.md) next.
