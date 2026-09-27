# Turnstile outage threshold: when to turn Supabase Auth CAPTCHA off and back on

Researched 2026-09-27 for issue #244. This note uses the vocabulary in `CONTEXT.md` (Student,
Maintainer, Ticket). Every claim in the findings sections has a citation. Supabase Auth source
links are pinned to commit
[`ce9a8ee`](https://github.com/supabase/auth/tree/ce9a8eee0cc042be8c7a42981a7ddae631e41d91)
(2026-09-22). Claims with no primary source are marked **unverified**. The threshold section at
the end is a proposal and has no sources.

**Outcome:** #244 adopted the named triggers T1–T4, the Maintainer canary and the turn-back-on
rule as written. A daily GitHub Actions workflow with a scoped, read-only Logs token watches for
T1, T2 and email bursts and opens an issue when one trips; the Maintainer keeps the canary and the
switch. See [ADR-0005](../adr/0005-sign-in-codes-are-guarded-by-one-turnstile-challenge-on-every-client.md).

## Question

Sign-in sends a Turnstile token with `POST /auth/v1/otp`. If Turnstile breaks for everyone,
signed-out Students are locked out. They cannot file a Ticket, and ADR-0001 rules out app
telemetry. What can the Maintainer observe, and which signals should make them turn CAPTCHA off
in the Supabase dashboard and later turn it back on?

## Summary

- **Supabase only sees failures that reach `/otp`.** If the widget fails in the browser or
  webview, the app never calls `/otp`, so Supabase logs nothing. The only traces are a *missing*
  request, possibly Turnstile Analytics ("issued" but not "solved"), and whatever the Student
  tells the Maintainer outside the app.
- **Failures that do reach `/otp` are clearly labelled.** A rejected token returns HTTP 400
  `captcha_failed` with Cloudflare's siteverify error codes in the message. If Supabase cannot
  reach siteverify, it returns HTTP 500 `unexpected_failure`. Each response writes an
  `auth_logs` line with `status` and `error_code`.
- **Free-plan retention is short.** Supabase keeps logs for 1 day and Turnstile Analytics looks
  back 7 days. Supabase has no built-in log alerts on any plan; its answer is log drains, which
  need Pro or above ($60 per drain per month).
- **Cloudflare's status page lists Turnstile as its own component** (and "Challenge Platform" as
  a separate one). Its own notification system can filter by component and deliver by email,
  webhook, Slack, Discord or Google Chat. The RSS/Atom feeds cover the whole page and cannot be
  filtered.
- **Neither vendor documents a fail-open policy.** Cloudflare's only advice is "Have fallback
  behavior for API failures". Supabase Auth itself fails closed: a siteverify error returns 500.
- **Webviews are supported only with caveats.** Cloudflare documents Android WebView and
  WKWebView setup, and lists embedded browsers under "limited support". WebView2 is not named.
  No prevalence figures are published.

## 1. Supabase observability of CAPTCHA failures

**Which routes check CAPTCHA.** `verifyCaptcha` runs on `/signup`, `/recover`, `/resend`,
`/magiclink`, `/otp`, `/token` and the SSO route. `/verify` does not have it
([api.go L229–L274](https://github.com/supabase/auth/blob/ce9a8eee0cc042be8c7a42981a7ddae631e41d91/internal/api/api.go#L229-L274)).
On `/token`, the `refresh_token`, `pkce` and `id_token` grants skip it
([middleware.go L283–L305](https://github.com/supabase/auth/blob/ce9a8eee0cc042be8c7a42981a7ddae631e41d91/internal/api/middleware.go#L283-L305)).
This confirms that refresh and verify are exempt. It also shows that **`/resend` is protected**.
On `/otp` the rate limiter runs *before* the CAPTCHA check (api.go L264–L265), so rejected
attempts still use up the Student's OTP rate-limit budget.

**When CAPTCHA is disabled, tokens are ignored.** `verifyCaptcha` returns immediately when
`Security.Captcha.Enabled` is false
([middleware.go L246–L248](https://github.com/supabase/auth/blob/ce9a8eee0cc042be8c7a42981a7ddae631e41d91/internal/api/middleware.go#L242-L281)).
This supports the emergency-switch design.

**What each failure returns** (same function):

| Condition | HTTP / `error_code` | Message |
|---|---|---|
| No token in `gotrue_meta_security.captcha_token` | 400 `captcha_failed` | `captcha protection: request disallowed (no captcha_token found)` |
| Siteverify answered `success:false` | 400 `captcha_failed` | `captcha protection: request disallowed (<error-codes joined by ", ">)` |
| Siteverify unreachable, timed out, or returned non-JSON | 500 `unexpected_failure` | `captcha verification process failed`; the internal error is `failed to verify captcha response: …` or `failed to decode captcha response: not JSON` |

The verifier calls `https://challenges.cloudflare.com/turnstile/v0/siteverify` once, with a
default 10 s timeout. It does not retry, and it does not check `hostname` or the sitekey
([captcha.go](https://github.com/supabase/auth/blob/ce9a8eee0cc042be8c7a42981a7ddae631e41d91/internal/security/captcha.go);
[configuration.go L852–L857](https://github.com/supabase/auth/blob/ce9a8eee0cc042be8c7a42981a7ddae631e41d91/internal/conf/configuration.go#L852-L857)).
The codes that can appear inside the parentheses are Cloudflare's siteverify codes:
`missing-input-secret`, `invalid-input-secret`, `missing-input-response`,
`invalid-input-response`, `bad-request`, `timeout-or-duplicate` and `internal-error`. Cloudflare
says to retry on `internal-error`
([Cloudflare server-side validation](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/)).
Tokens are valid for five minutes and can be used once (same page).

Supabase's public descriptions: `captcha_failed` means "CAPTCHA challenge could not be verified
with the CAPTCHA provider. Check your CAPTCHA integration." `unexpected_failure` means "Auth
service is degraded or a bug is present, without a specific reason"
([Supabase error codes](https://supabase.com/docs/guides/auth/debugging/error-codes)).

**How it is logged.** The error handler sets the `x-sb-error-code` response header and an
`error` log field
([errors.go L151–L164](https://github.com/supabase/auth/blob/ce9a8eee0cc042be8c7a42981a7ddae631e41d91/internal/api/errors.go#L151-L164)).
The request logger then writes a `request completed` entry with `status`, `duration`,
`error_code`, `path`, `method` and `remote_addr`. 4xx responses are logged at `warning` level and
5xx at `error`
([request-logger.go](https://github.com/supabase/auth/blob/ce9a8eee0cc042be8c7a42981a7ddae631e41d91/internal/observability/request-logger.go#L46-L150)).
The path Auth logs is `/otp`; it does not include the `/auth/v1` gateway prefix, as the
`/token` check in middleware.go shows.

**Where to query it.** In Studio, open Logs, choose the **Auth** log type, and filter by status,
path or message text ([Logs in Studio](https://supabase.com/docs/guides/observability/logs)). For
SQL, use Explorer → **Run SQL** → query source **Logs** (ClickHouse). Each event is a row in
`logs`; `source = 'auth_logs'` selects Auth events, and service fields are strings in
`log_attributes['…']`. `select *` and `count(*)` are rejected
([Query logs with SQL](https://supabase.com/docs/guides/observability/advanced-log-filtering);
[Log sources and fields](https://supabase.com/docs/guides/observability/log-field-reference)).
The published field list for `auth_logs` includes `status`, `path`, `msg`, `level` and
`remote_addr`
([log-constants.ts](https://github.com/supabase/supabase/blob/36371de15127206280d2d40786e8578dfe1b681a/packages/shared-data/log-constants.ts#L95-L121)).
It does **not** list `error_code` or `error`, even though the source emits them. Before relying
on those two fields, run Supabase's key-discovery query with `source = 'auth_logs'`.

```sql
-- Send-code outcomes per hour (Explorer > Run SQL > Logs; pick the time range there)
select toStartOfHour(timestamp) as hour,
  countIf(toInt32OrZero(log_attributes['status']) = 200)            as sent,
  countIf(log_attributes['error_code'] = 'captcha_failed')          as captcha_rejected,
  countIf(toInt32OrZero(log_attributes['status']) between 500 and 599) as server_errors
from logs
where source = 'auth_logs'
  and log_attributes['path'] = '/otp'
group by hour
order by hour desc
limit 48;

-- Detail of CAPTCHA failures, including the siteverify reason
select timestamp, log_attributes['path'] as path, log_attributes['status'] as status,
  log_attributes['error_code'] as error_code, log_attributes['error'] as error, event_message
from logs
where source = 'auth_logs'
  and (log_attributes['error_code'] = 'captcha_failed'
       or event_message ilike '%captcha%')
order by timestamp desc
limit 100;
```

The same queries can be run through the Management API
(`GET /v1/projects/{ref}/analytics/endpoints/logs` with `sql`, `iso_timestamp_start` and
`iso_timestamp_end`; each call covers at most 24 h) or through Supabase MCP `query_logs`
([Query logs with SQL](https://supabase.com/docs/guides/observability/advanced-log-filtering)).

**Retention.** Log retention (API & Database) is Free 1 day, Pro 7 days, Team 28 days and
Enterprise 90 days
([pricing.ts](https://github.com/supabase/supabase/blob/36371de15127206280d2d40786e8578dfe1b681a/packages/shared-data/pricing.ts#L588-L597);
[Supabase pricing](https://supabase.com/pricing)). If a project scans more than its log-query
allowance, the next month is degraded: retention drops to 1 hour on Free and 24 hours on paid
plans, and queries are limited to 10 per minute
([Manage Logs Query usage](https://supabase.com/docs/guides/platform/manage-your-usage/logs-query)).

**Alerts.** Supabase documents no built-in log alerts or notifications. The documented options
are:

- **Log drains.** These stream all logs to an external vendor "to build alerts". They are
  available "only … on Pro, Team and Enterprise Plans"
  ([Log drains](https://supabase.com/docs/guides/observability/log-drains)) and cost $60 per
  drain per month plus events and egress (pricing.ts, above).
- **Polling the Management API logs endpoint.** Supabase discourages scripted polling because
  every query re-scans data and counts against the allowance
  ([Manage Logs Query usage](https://supabase.com/docs/guides/platform/manage-your-usage/logs-query)).
- **A scheduled read-only "monitoring agent" prompt run through MCP**
  ([Hire an agent](https://supabase.com/docs/guides/observability/automate-with-agents)). The
  suggested thresholds (at least 20 server errors, a 1% error rate, and at least 100 responses
  per window) are meant for much larger projects
  ([Detection checks](https://supabase.com/docs/guides/observability/detecting)).

The Prometheus Metrics API covers Postgres series only
([Metrics](https://supabase.com/docs/guides/observability/metrics)).

**The switch can be scripted.** `PATCH /v1/projects/{ref}/config/auth` (scope `auth:write`)
accepts `security_captcha_enabled`, `security_captcha_provider` and `security_captcha_secret`
([Management API reference](https://supabase.com/docs/reference/api/v1-update-auth-service-config);
[api_v1_openapi.json](https://github.com/supabase/supabase/blob/36371de15127206280d2d40786e8578dfe1b681a/apps/docs/spec/api_v1_openapi.json)).
The dashboard setting is under Authentication → Bot and Abuse Protection
([Auth CAPTCHA guide](https://supabase.com/docs/guides/auth/auth-captcha)). Supabase's status
page has an **Auth** component
([status.supabase.com components API](https://status.supabase.com/api/v2/components.json)).

## 2. Turnstile free-plan analytics

**Metrics.** The Turnstile dashboard shows:

- **Challenge outcomes:** issued, solved and unsolved counts, plus "Likely human" and "Likely
  bot" ratios.
- **Solve rates:** non-interactive, interactive and pre-clearance solves. The
  interactive/non-interactive split is shown for managed mode.
- **Token validation:** siteverify requests, valid tokens and invalid tokens.
- **Top lists:** hostnames, browsers, countries, user agents, ASNs, operating systems and
  source IPs.

Sources: [Turnstile Analytics](https://developers.cloudflare.com/turnstile/turnstile-analytics/),
[Challenge outcomes](https://developers.cloudflare.com/turnstile/turnstile-analytics/challenge-outcomes/),
[Token validation](https://developers.cloudflare.com/turnstile/turnstile-analytics/token-validation/).
The client-side `action` value (up to 32 characters) can tell widgets apart in analytics
([Widget configurations](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/widget-configurations/)).
That makes it possible to separate web and native-challenge-page traffic without any app
telemetry.

**Retention.** The analytics lookback is at most 7 days on Free and 30 days on Enterprise
([Turnstile plans](https://developers.cloudflare.com/turnstile/plans/)).

**Alerting.** The Cloudflare Notifications catalogue has **no Turnstile notification**
([Available Notifications](https://developers.cloudflare.com/notifications/notification-available/);
[catalogue source](https://github.com/cloudflare/cloudflare-docs/blob/9525fb5b8ab78c58bd5e941dea9fd75a366b6eac/src/content/notifications/index.yaml)).
It does have **Incident Alerts** for Cloudflare Status incidents, "available on all Cloudflare
plans". These can be filtered by impact level and by component (catalogue lines 86–96). Webhook
delivery for dashboard notifications requires a paid service; Free accounts get email
([Notifications get started](https://developers.cloudflare.com/notifications/get-started/)).

**GraphQL.** A `turnstileAdaptiveGroups` dataset exists
([GraphQL datasets](https://developers.cloudflare.com/data-localization/metadata-boundary/graphql-datasets/)).
Whether a Free account can use it, and how far back, is not documented. Cloudflare says only that
datasets and lookback depend on plan and can be checked with the `settings` node
([Settings node](https://developers.cloudflare.com/analytics/graphql-api/features/discovery/settings/);
[Limits](https://developers.cloudflare.com/analytics/graphql-api/limits/)). **Unverified** for
Free.

## 3. Turnstile client error codes

The current table was last updated 2026-09-25
([Error codes](https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/error-codes/);
[commit f3e9df3](https://github.com/cloudflare/cloudflare-docs/commit/f3e9df328b)). A `*`
means the remaining digits vary and are internal.

| Code | Meaning (Cloudflare) | Retry | Likely owner |
|---|---|---|---|
| `110100`, `110110`, `400020` | Invalid or unknown sitekey | No | Our configuration |
| `110200` | Domain not authorized | No | Our configuration (Hostname Management) |
| `400021` | Sitekey region does not match script domain | No | Our configuration |
| `400070` | Sitekey disabled | No | Our configuration or Cloudflare account |
| `110600` | Challenge timed out (clock or slow solve) | Yes | Student's environment |
| `110620` | Interaction timed out | Yes | Student (did not interact) |
| `200100` | Clock or cache problem (intermediary cached challenge) | No | Student's environment or network |
| `200500` | Iframe load error: "Check if `challenges.cloudflare.com` is blocked" | Yes | Network or content blocker, **or** Cloudflare outage |
| `300*`, `600*` | Generic challenge failure, "Bot behavior detected" | Yes | Student's environment (or a false positive) |

The March 2026 revision removed an older, longer table, including the `100xxx`–`106xxx`,
`110500` "Browser not supported" and `120xxx` rows
([commit 76962f5](https://github.com/cloudflare/cloudflare-docs/commit/76962f5a53)). The
client-side errors page still uses family `100` in its example handler ("Please refresh the page
and try again"). By default Turnstile retries automatically, so the error callback may fire
several times for one problem. `retry: 'never'` plus `turnstile.reset()` hands retry control to
the app, and `retry-interval` sets the spacing
([Client-side errors](https://developers.cloudflare.com/turnstile/troubleshooting/client-side-errors/)).
A `401` on the Private Access Token request, and DNS failures on `*.challenges.cloudflare.com`
subdomains, are expected and do not block the challenge
([Challenge solve issues](https://developers.cloudflare.com/cloudflare-challenges/troubleshooting/challenge-solve-issues/)).
**No code distinguishes "Cloudflare is down" from "this network blocks Cloudflare"**. `200500`
covers both.

The Student-side checklist, from the same page: check browser support, disable extensions,
enable JavaScript, try private mode, try another browser or device, turn off VPN or proxy, and
switch networks (e.g. to a mobile hotspot). A widget that fails offers **Submit Feedback**, but
that report goes to Cloudflare, not to the site owner
([Feedback reports](https://developers.cloudflare.com/turnstile/troubleshooting/feedback-reports/)).

## 4. Cloudflare status page

Turnstile is its own component on cloudflarestatus.com: `Turnstile` (id `m4jywscr0n0k`) in the
"Cloudflare Sites and Services" group. `Challenge Platform` (id `x0tkn0hzrtw7`) is separate
([components API](https://www.cloudflarestatus.com/api/v2/components.json), checked 2026-09-27).
The status page runs its own notification service, with a separate account and magic-link
sign-in. Rules filter on type, impact, status and **components**. Destinations are email,
webhook, Slack, Discord and Google Chat
([Status Page Notifications](https://www.cloudflarestatus.com/docs/notifications)). The RSS and
Atom feeds (`/api/v3/incidents.rss`, `.atom`) are page-wide, with no component filter
([Status API](https://www.cloudflarestatus.com/api)). A per-component poll is possible through
`/api/v2/components.json`. Cloudflare asks for an identifying User-Agent and says not to scrape
HTML (same page). None of the 50 most recent incidents (back to 2026-09-09) involved
Turnstile or Challenge Platform
([incidents API](https://www.cloudflarestatus.com/api/v2/incidents.json)).

## 5. Known failure environments

- **Blocked `challenges.cloudflare.com`.** Cloudflare names network restrictions, VPNs and
  proxies as causes and suggests switching networks. It gives no figures and does not name
  corporate or hospital networks specifically
  ([Challenge solve issues](https://developers.cloudflare.com/cloudflare-challenges/troubleshooting/challenge-solve-issues/)).
- **Content and privacy blockers.** Ad blockers, script blockers, fingerprinting protection and
  canvas blockers "can interfere"
  ([Supported browsers](https://developers.cloudflare.com/cloudflare-challenges/reference/supported-browsers/)).
- **Unsupported and limited environments.** Internet Explorer, command-line tools and automation
  frameworks are unsupported. "Custom or heavily modified browser engines and embedded browsers"
  have limited support, as do browsers or operating systems more than five years old or without
  security updates for two years. "WebViews in mobile applications may have limited
  functionality" (same page).
- **Webviews.** Turnstile does not run natively; use a WebView. The requirements are JavaScript,
  DOM storage, access to `challenges.cloudflare.com`, `about:blank` and `about:srcdoc`, a
  consistent User-Agent, cookie persistence (Android: third-party cookies enabled), and a CSP
  that allows `challenges.cloudflare.com` in script-src, connect-src and frame-src. Cloudflare
  gives Android WebView, WKWebView, React Native and Flutter (`flutter_inappwebview`) examples.
  Changing the User-Agent mid-session makes challenges fail
  ([Mobile implementation](https://developers.cloudflare.com/turnstile/get-started/mobile-implementation/)).
  **Windows WebView2 is not mentioned anywhere in the Turnstile or Challenges docs.**
- **Hostnames.** A hostname entry also authorizes its subdomains. Paths and wildcards are not
  allowed ([Hostname management](https://developers.cloudflare.com/turnstile/additional-configuration/hostname-management/)).
  The hosted challenge page therefore needs `mshamblin5150-code.github.io` (or a parent) on the
  widget, or it returns `110200`.
- **Prevalence.** Cloudflare publishes no failure-rate or blocked-network statistics.

## 6. Fail-open vs fail-closed guidance

- **Cloudflare.** The server-side best practices say "Have fallback behavior for API failures",
  "Implement retry logic", and "Set reasonable timeouts". They do not say whether the fallback
  should allow or deny
  ([Server-side validation](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/)).
  No Turnstile or Challenges page uses the terms "fail open", "fail closed" or "outage" (repo
  search, commit `9525fb5`).
- **Supabase.** The guides do not cover CAPTCHA outage handling
  ([Auth CAPTCHA guide](https://supabase.com/docs/guides/auth/auth-captcha)). The code fails
  closed (500, no retry; section 1). The only exit is turning CAPTCHA off, which makes the
  server ignore tokens. With CAPTCHA off, the OTP, verify and email rate limits still apply
  ([Rate limits](https://supabase.com/docs/guides/auth/rate-limits)). Supabase calls CAPTCHA "the
  most effective way to control bots" for email-sending abuse
  ([Custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp)). That is the risk accepted
  while the switch is off.

---

## Candidate threshold (proposal, not sourced)

Everything below is a recommendation based on the findings. It is not vendor guidance.

**Use named triggers, not rates.** With a handful of Students, a day may have zero to three
send-code attempts. A percentage is noise, and Supabase's own detection defaults require at
least 100 responses per window. Base the decision on specific events, and confirm with a
Maintainer canary: a sign-in the Maintainer runs from a signed-out device.

**Make the Student's failure readable (no telemetry).** When the widget fails, the app shows the
Turnstile error code and tells the Student to text or email the Maintainer. This out-of-band
report replaces a Ticket. Nothing is stored or sent automatically, so ADR-0001 is respected. Set
distinct `action` values (`web-send-code`, `native-send-code`) so Turnstile Analytics can tell
the two paths apart.

**Standing setup (one-time):**
1. On cloudflarestatus.com, subscribe by email with a rule for components **Turnstile** and
   **Challenge Platform**, impact ≥ Minor, all statuses.
2. Optionally, in the Cloudflare dashboard, add Incident Alerts filtered to the same components.
3. Bookmark the two SQL queries above as Explorer snippets. Free logs last only **1 day**, so run
   them on the day of any report.

**What to check first, in order (about 10 minutes):**
1. cloudflarestatus.com: Turnstile and Challenge Platform components. status.supabase.com: Auth.
2. Supabase Auth logs, last 24 h, `/otp`:
   - 500 `unexpected_failure` whose error mentions captcha → siteverify is unreachable
     (Cloudflare side).
   - `captcha_failed (invalid-input-secret | missing-input-secret)` → our secret is wrong. Fix
     it rather than switching off.
   - `captcha_failed (no captcha_token found)` → a client that is not sending tokens (old build
     or app bug).
   - `captcha_failed (invalid-input-response | timeout-or-duplicate)` → an individual token
     problem.
   - **No `/otp` rows at all** while a Student reports failure → the widget is failing
     client-side.
3. Maintainer canary: signed out, press Send code on (a) the web app in a stock browser and
   (b) one native app, first on home broadband and then on mobile data. Note any error code.
4. Turnstile Analytics (7 days): issued vs solved per `action` and hostname, and siteverify
   valid vs invalid.
5. Turnstile widget: the hostname list still includes `mshamblin5150-code.github.io`, and the
   sitekey is not disabled.

**Turn CAPTCHA OFF when any one of these holds:**
- **T1.** Cloudflare has an open incident on Turnstile or Challenge Platform, **and** the canary
  fails on at least one path.
- **T2.** Auth logs show a CAPTCHA-related 500 `unexpected_failure` on `/otp` two or more times
  within 30 minutes, with no successful `/otp` in between (siteverify down for Supabase).
- **T3.** The canary fails on **both** networks, **or** on both web and native, with a
  config-class code (`110100`, `110110`, `110200`, `400020`, `400021`, `400070`) or with
  `200500`, and the cause cannot be fixed within 30 minutes. For config codes, fixing the
  configuration is always preferred to switching off.
- **T4.** Two or more Students, on different networks, report that they cannot send a code
  within 24 hours, and the canary reproduces the failure.

**Do NOT switch off for:**
- One Student on one network (hospital Wi-Fi, VPN, content blocker). Walk them through
  Cloudflare's checklist; mobile data is the quickest test.
- A single `300*`, `600*`, `110600` or `110620`.
- A failure on only one native platform. Point the Student to the web app in a normal browser,
  and treat the platform failure as an app bug.

**Turn CAPTCHA back ON when all of these hold:**
1. The Cloudflare incident is marked Resolved (or the config fix is deployed), and at least
   1 hour has passed with no new incident.
2. The canary passes on web and on every native platform the Maintainer can test, on two
   networks.
3. The Maintainer can check the Auth logs again within 24 hours of re-enabling.

After re-enabling, check the logs the same day and the next day. Any `captcha_failed` or
CAPTCHA-related 500 on `/otp` means switching off again under T2 or T3. Ask the Students who
reported the problem to try once more.

**Longest time off:** review daily. If CAPTCHA has been off for 7 days, record in the issue why
it stays off, and check the Auth logs for bursts of OTP emails (abuse) while protection is down.

**Runbook text (for the release or security runbook, e.g. `docs/release-security-checklist.md`):**

> **Turnstile outage switch.** Off: Supabase dashboard → Authentication → Bot and Abuse
> Protection → disable CAPTCHA (or `PATCH /v1/projects/{ref}/config/auth`
> `{"security_captcha_enabled": false}`). Apps keep sending tokens; the server ignores them.
> Refresh and verify are never affected.
> Triggers: T1–T4 above. Not a trigger: one Student, one network, one platform, or one
> bot-class code.
> On: incident resolved for 1 hour or more, canary passes on web and native on two networks,
> and the Maintainer is available to check Auth logs for 24 hours. Re-enable with the same
> setting; confirm the stored secret is unchanged.
> Log every flip (time, trigger, evidence, including a copy of the relevant Auth log lines,
> because Free keeps logs for 1 day) in the tracking issue.

## Open questions

- Does hosted Supabase put the `error_code` and `error` logrus fields into
  `log_attributes['error_code']` and `log_attributes['error']`? They are emitted by the source
  but missing from the published `auth_logs` field list. Run the `mapKeys` discovery query once
  CAPTCHA is on.
- Does the "Log retention (API & Database)" figure (1 day on Free) also apply to `auth_logs`?
  The pricing table does not name Auth.
- Can a Free Cloudflare account query `turnstileAdaptiveGroups` through GraphQL, and with what
  lookback? Check with the `settings` node.
- Does the Cloudflare dashboard's Incident Alerts component filter include Turnstile? The
  status page lists it, but the Notifications docs do not enumerate components.
- Windows WebView2 is not documented by Cloudflare; test it directly. Also: do Android WebView
  and WKWebView in the chosen Flutter plugin meet the cookie, DOM storage and User-Agent
  requirements?
- Is the Management API logs endpoint available on the Free plan? The docs set no plan limit,
  but none is stated either.
- Can the hosted CAPTCHA timeout (default 10 s in source) be changed on supabase.com projects?
