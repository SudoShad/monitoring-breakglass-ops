# Monitoring & Break-Glass Ops

**Author:** Shadman Bari · [shadman.io](https://shadman.io) · [LinkedIn](https://linkedin.com/in/shadman-bari) · shadman@shadman.io  
**Focus:** Desktop Support / IT Support / Jr Sysadmin — monitoring alert triage, incident communication, and emergency (break-glass) access patterns  
**Companions:** [helpdesk-graph-toolkit](https://github.com/SudoShad/helpdesk-graph-toolkit) · [endpoint-hardening-baseline](https://github.com/SudoShad/endpoint-hardening-baseline) · [ad-intune-mini-tenant](https://github.com/SudoShad/ad-intune-mini-tenant) *(PARKED)*

Portfolio lab that shows how a junior sysadmin / deskside engineer thinks when monitoring fires and when emergency privileged access is required. Runnable health probes and alert parsers ship alongside honest runbooks — no live tenant required.

> No secrets in this repo. No fake screenshots or invented SLAs. Mutating stubs default to **dry-run**. Sample tickets and alerts are clearly marked as examples.

---

## Problem

Helpdesk and junior sysadmin interviews ask more than "I can ping a host." Employers want evidence you can:

- Triage monitoring alerts by severity (P1–P3) without panicking
- Communicate cleanly during an incident (who / what / next update)
- Treat break-glass / emergency admin access as a controlled, logged, time-bound exception — not a standing privilege
- Revoke elevated sessions after the window closes

Most "ops" GitHub repos either dump dashboards with no procedure or hand-wave break-glass with real credentials. This one is documentation + demos you can run locally and talk through in an interview.

---

## What it does

| Asset | Purpose |
|-------|---------|
| [`scripts/check-service-health.ps1`](scripts/check-service-health.ps1) / [`.sh`](scripts/check-service-health.sh) | HTTP or TCP health probe with clear exit codes (0 = OK, 1 = fail, 2 = usage) |
| [`scripts/parse-alert.ps1`](scripts/parse-alert.ps1) | Sample alert JSON → severity + recommended action |
| [`scripts/breakglass-request.ps1`](scripts/breakglass-request.ps1) | Mock break-glass ticket + dual-control approval checklist (no real IdP calls) |
| [`scripts/revoke-session-stub.ps1`](scripts/revoke-session-stub.ps1) | Documents Graph session-revoke pattern; **dry-run by default** |
| [`docs/RUNBOOK.md`](docs/RUNBOOK.md) | Alert triage ladder, escalation, comms template, post-incident notes |
| [`docs/BREAK-GLASS.md`](docs/BREAK-GLASS.md) | Emergency access policy patterns (when / dual-control / logging / revoke / audit) |
| [`docs/SETUP.md`](docs/SETUP.md) | Prerequisites — run everything without a tenant |
| [`examples/`](examples/) | Sample alert payloads, webhook-ish alert, approved break-glass ticket JSON |

---

## How to run (no tenant)

```bash
# HTTP health probe (bash)
./scripts/check-service-health.sh --url https://example.com --timeout 5

# TCP probe
./scripts/check-service-health.sh --host example.com --port 443

# Parse a sample alert (PowerShell 7 or Windows PowerShell 5.1+)
pwsh ./scripts/parse-alert.ps1 -Path ./examples/sample-alert-p1.json

# Mock break-glass request + checklist
pwsh ./scripts/breakglass-request.ps1 -Requester 'jdoe' -Reason 'P1 outage — restore read-only DB access' -DurationMinutes 60

# Documented revoke stub (prints Graph pattern; does not call Graph unless you opt in and supply env)
pwsh ./scripts/revoke-session-stub.ps1 -UserPrincipalName 'jdoe@contoso.example' -WhatIf
```

Full prerequisites: [`docs/SETUP.md`](docs/SETUP.md).

---

## Safety

- **Dry-run / `-WhatIf` by default** on anything that could mutate identity sessions.
- **No secrets, tenant IDs, tokens, or real tickets** belong in git. `out/` is gitignored except its README.
- Break-glass docs emphasize dual-control, time-bound elevation, and revoke — never standing God-mode accounts in source control.
- Sample JSON under `examples/` uses fictional names (`contoso.example`, `jdoe`).

---

## Resume bullets (paste-ready)

> Built a public **monitoring & break-glass ops lab** (`monitoring-breakglass-ops`) with alert triage runbooks (P1–P3), emergency-access policy patterns (dual-control, time-bound elevation, revoke, audit), and runnable health-probe / alert-parse / mock ticket scripts (PowerShell + bash) that run without a live tenant.

> Documented junior-sysadmin incident communication templates and post-incident notes alongside dry-run Graph session-revoke stubs, pairing ops hygiene with the companion helpdesk Graph toolkit.

---

## Skills demonstrated

- Monitoring alert triage and severity ladders (P1–P3)  
- Incident communication and escalation hygiene  
- Break-glass / emergency privileged access patterns (dual-control, logging, revoke)  
- HTTP/TCP health probing with scriptable exit codes  
- PowerShell 5.1 / 7 + bash scripting for deskside / Jr Sysadmin work  
- Honest portfolio practice (dry-run defaults; no secrets; examples marked as such)

---

## Repo map

| Path | Purpose |
|------|---------|
| [`scripts/`](scripts/) | Health probe, alert parser, break-glass mock, revoke stub |
| [`docs/RUNBOOK.md`](docs/RUNBOOK.md) | Triage ladder + comms + post-incident |
| [`docs/BREAK-GLASS.md`](docs/BREAK-GLASS.md) | Emergency access policy patterns |
| [`docs/SETUP.md`](docs/SETUP.md) | Local run without a tenant |
| [`examples/`](examples/) | Sample alerts + approved ticket JSON |
| [`tests/Smoke-Syntax.ps1`](tests/Smoke-Syntax.ps1) | Parser smoke test (no network / no Graph) |

---

## Related labs

| Repo | Role |
|------|------|
| [helpdesk-graph-toolkit](https://github.com/SudoShad/helpdesk-graph-toolkit) | PowerShell + Graph helpdesk automation (BitLocker, stale devices, password reset, session revoke) |
| [endpoint-hardening-baseline](https://github.com/SudoShad/endpoint-hardening-baseline) | CIS-inspired Intune / policy-as-code Windows hardening |
| [ad-intune-mini-tenant](https://github.com/SudoShad/ad-intune-mini-tenant) | Entra + Intune enroll lab — **PARKED** |

---

## Requirements

- bash (Linux/macOS/WSL) **or** PowerShell 5.1+ / PowerShell 7+  
- Optional: `curl` for the shell health probe  
- Optional: Microsoft Graph modules only if you intentionally leave dry-run on the revoke stub (see SETUP)

---

## License

MIT © 2026 Shadman Bari — see [LICENSE](LICENSE).
