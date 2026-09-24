# Break-glass — emergency access patterns

Defense-in-depth patterns for **time-bound privileged access** when standard helpdesk rights are not enough. This document describes policy shapes suitable for a junior sysadmin interview — it does **not** ship credentials, standing admin passwords, or live IdP integrations.

> Never store break-glass passwords, certificates, or refresh tokens in this repository. Sample tickets under `examples/` are fiction.

---

## 1. What “break-glass” means here

Break-glass (also called emergency access) is a **controlled exception** to normal least-privilege:

- Used when production is down / security incident / locked-out admin path  
- Requires **justification + approval**  
- Is **time-bound** (minutes to a few hours, not days)  
- Is **logged and reviewed** after use  
- Ends with **explicit revoke** of elevated sessions / group membership / PIM activation  

It is **not**: a shared Domain Admin password in a wiki, a permanent Global Administrator with MFA disabled “just in case,” or an untracked local admin on every laptop.

---

## 2. When to use (and when not to)

| Use break-glass | Do not use break-glass |
|-----------------|------------------------|
| P1 outage and standard role cannot remediate | Convenience (“faster than waiting for IAM”) |
| All normal admin paths locked out (IdP misconfig, MFA provider outage) | Standing daily admin work |
| Confirmed security incident needing rapid containment with elevated rights | Curiosity / “lab on prod” |
| Vendor bridge requires a named elevated operator with dual control | Skipping change control for a low-risk P3 |

If a normal privileged identity (PIM-eligible role, JIT group) can be activated through the standard path, prefer that. Break-glass is the fire extinguisher, not the coffee maker.

---

## 3. Dual-control (four eyes)

Minimum healthy pattern:

1. **Requester** opens a ticket with severity, system, reason, requested role/scope, and duration.  
2. **Approver** (different person; ideally different shift / manager / security) reviews impact and duration.  
3. Elevation proceeds only after approval is recorded.  
4. For the highest tiers (cloud Global Admin / Domain Admin), prefer **two approvers** or security + IT manager.

`scripts/breakglass-request.ps1` prints an approval checklist and can write a mock ticket JSON under `./out/` for interview demos.

---

## 4. Time-bound elevation

| Control | Practice |
|---------|----------|
| Duration | Default short (e.g. 30–60 minutes); extend only with re-approval |
| Scope | Narrowest role that unblocks the fix (read-only DB vs Global Admin) |
| Clock | Record start / planned end in the ticket; calendar reminder to revoke |
| Auto-expiry | Prefer PIM / JIT group expiry over permanent group adds |

Standing “emergency” accounts with never-expiring passwords are an anti-pattern. If an offline emergency account exists for IdP lockout, it should be **physically / procedurally controlled**, monitored, and tested on a schedule — never pasted into git.

---

## 5. Logging & audit trail

Every break-glass use should leave:

- Ticket id + severity + business justification  
- Requester, approver(s), timestamps  
- Role / group / resource granted  
- Actions taken while elevated (high level)  
- Revoke confirmation (session revoke, group remove, PIM end)  
- Post-incident link  

Monitoring should alert on activation of emergency roles (Entra audit logs, PIM alerts, AD privileged group changes). Silence after break-glass is a finding.

---

## 6. Revoke checklist (mandatory)

When the window ends — or earlier if the incident is contained:

1. End PIM activation / remove temporary privileged group membership.  
2. **Revoke sign-in sessions** for the elevated identity (refresh tokens) — see stub below and companion helpdesk toolkit.  
3. Rotate any password or credential that was used if it was a shared emergency secret (and treat that as a follow-up to eliminate shared secrets).  
4. Confirm monitoring shows the role is inactive.  
5. Close the ticket with audit fields filled.

Dry-run demo:

```powershell
pwsh ./scripts/revoke-session-stub.ps1 -UserPrincipalName 'jdoe@contoso.example' -WhatIf
```

Live revoke belongs in a **lab tenant** via [helpdesk-graph-toolkit](https://github.com/SudoShad/helpdesk-graph-toolkit) `Revoke-UserSessions.ps1`, with `-WhatIf` until you intend to mutate.

---

## 7. Defense-in-depth (stack the controls)

Do not rely on a single control:

1. **Prevent** — least privilege, PIM, no standing Global Admin for daily work  
2. **Detect** — alert on emergency role activation and privileged group changes  
3. **Respond** — runbooks + dual-control break-glass + session revoke  
4. **Recover** — known-good admin paths tested quarterly; endpoint hardening (see companion baseline) so one compromised workstation is not game over  
5. **Review** — monthly sample of break-glass tickets for duration creep and rubber-stamp approvals  

---

## 8. What this repo will never include

- Real passwords, TAP codes, certificates, or client secrets  
- Production tenant IDs or real user UPNs  
- Instructions to disable MFA on emergency accounts as a “solution”  
- Unscoped “grant Domain Admin forever” scripts  

If a sample needs an identity, it uses fiction: `jdoe@contoso.example`, ticket `BG-1001`, etc.
