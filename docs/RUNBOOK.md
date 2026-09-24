# Runbook — alert triage, escalation, communication

Operator-facing ladder for monitoring alerts. Pair with [`BREAK-GLASS.md`](BREAK-GLASS.md) when elevated access is required to remediate.

> Lab / portfolio guidance. Map severities to your employer’s ITSM definitions before production use.

---

## 1. Severity ladder (P1–P3)

| Severity | Typical signal | Response goal | Who |
|----------|----------------|---------------|-----|
| **P1** | Customer-facing outage, auth down, ransomware indicators, widespread VPN failure | Acknowledge fast; join bridge; restore or mitigate | On-call + escalate early |
| **P2** | Degraded service, single site / single app down, backup job failed overnight with business impact today | Stabilize within the shift; ticket + owner | Tier 1 / Tier 2 |
| **P3** | Noisy disk warning, cert expiring in 30+ days, non-critical job failure with workaround | Schedule; document; do not page overnight | Queue / backlog |

**Rule of thumb:** If users cannot work *right now* and there is no workaround, treat as P1 until proven otherwise. Downgrade with evidence, not hope.

---

## 2. First five minutes (any severity)

1. **Acknowledge** the alert in the monitoring / ITSM tool so others know someone owns it.  
2. **Read the payload** — host, service, metric, threshold, start time (use `parse-alert.ps1` on sample JSON to practice).  
3. **Confirm blast radius** — one user, one site, or org-wide?  
4. **Check recent change** — deployments, Intune pushes, GPO, DNS, cert renewals.  
5. **Pick a lane:** remediate with standard access, escalate, or open a **break-glass** request if privileged access is required (see BREAK-GLASS).

Health sanity check (example):

```bash
./scripts/check-service-health.sh --url https://app.contoso.example/health --timeout 5
```

---

## 3. Escalation

Escalate when:

- Severity is P1 and you lack access or expertise within ~10–15 minutes  
- Security indicators (impossible travel + mass mailbox rules, EDR critical, ransomware notes)  
- Vendor / ISP / cloud status pages show a broader incident  
- Break-glass is needed and you are not an authorized requester / approver

**Escalate with:** severity, start time, impact (users / sites), what you already tried, link to ticket / alert id. Do not escalate with only “it’s broken.”

---

## 4. Communication template

Post to the incident channel / ticket (adapt tone to your org):

```text
INCIDENT UPDATE — {P1|P2|P3} — {short title}
Time (ET): {HH:MM}
Impact: {who / what is broken}
Status: Investigating | Mitigating | Monitoring | Resolved
Owner: {you}
Next update by: {HH:MM}
Actions so far:
- {bullet}
- {bullet}
Ask: {anything needed from others}
```

Update on the promised cadence even if “no change — still investigating.” Silence causes duplicate pages.

---

## 5. During remediation

- Prefer **least privilege** and documented runbooks over improvisation.  
- If you need emergency admin rights, follow [`BREAK-GLASS.md`](BREAK-GLASS.md) — request → dual approval → time-bound use → revoke → audit note.  
- Capture commands / portal clicks in the ticket (enough for a peer to replay).  
- Do not clear alerts until the underlying condition is fixed or an accepted workaround is in place.

---

## 6. Post-incident notes (short)

Within one business day for P1 (and meaningful P2):

| Field | Example |
|-------|---------|
| Summary | What failed and user impact |
| Timeline | Detect → ack → mitigate → resolve (clock times) |
| Root cause | Factual; “unknown — still investigating” is OK temporarily |
| Fix / workaround | What restored service |
| Follow-ups | Monitoring gap, runbook gap, access gap, hardening gap |
| Break-glass used? | Yes/No — ticket id, who approved, revoke confirmed |

Honest follow-ups beat blame. Feed gaps into the companion repos where relevant (e.g. session revoke → helpdesk toolkit; endpoint control gap → hardening baseline).

---

## 7. Script cheat sheet

| Situation | Script |
|-----------|--------|
| Is the endpoint answering? | `check-service-health.ps1` / `.sh` |
| What does this alert mean? | `parse-alert.ps1 -Path examples/...` |
| Need emergency access ticket shape? | `breakglass-request.ps1` |
| After elevated session / compromise | `revoke-session-stub.ps1 -WhatIf` (or live revoke via helpdesk toolkit in a lab) |
