---
status: accepted
---

# Sign-in codes are guarded by one Turnstile challenge on every client

Sign-ups are open to anyone, and every Send code creates an account and sends a real email through the custom sender, so a bot can burn the email quota and damage sender reputation. Supabase Auth's built-in CAPTCHA covers the code request for the whole project, not per client. **Every client must pass one Cloudflare Turnstile challenge (managed mode, interaction-only) before requesting a sign-in code. The web app renders the widget; the Windows, Android and iOS apps open a hosted challenge page on the same GitHub Pages site in an embedded web view and take the token from it. Turning CAPTCHA off in the Supabase dashboard is the emergency switch: clients keep sending tokens and the server ignores them.** Grilled in #244.

## Considered options

- **hCaptcha.** Rejected. Its free tier shows image puzzles, and its accessibility route needs a separate cookie sign-up; Turnstile is free with unlimited challenges and rarely shows anything.
- **A server-side gateway that requests codes for native apps with admin credentials.** Rejected. Without app attestation (Play Integrity, App Attest, and nothing for Windows) it is an unguarded back door around the check.
- **The system browser with a deep link back into the app.** Rejected. Deep links into a Windows desktop app are awkward, and emailed codes were chosen in #230 to avoid redirects.

## Consequences

- Token refresh, code verification and sign-out are exempt, so signed-in Connected Devices are unaffected by the check or by a Turnstile outage; only fresh sign-ins depend on it.
- Clients ship token support before CAPTCHA is switched on, because the setting takes effect for every build at once.
- The challenge page's hostname must stay on the Turnstile widget's hostname list; moving the web app off `mshamblin5150-code.github.io` means updating the widget too.
- When to flip the switch is operational and lives in the release runbook, informed by `docs/research/turnstile-outage-threshold.md`.
