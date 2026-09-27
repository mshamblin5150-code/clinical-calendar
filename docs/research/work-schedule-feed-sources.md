# Work Schedule Feed sources: which employer scheduling systems publish a per-employee calendar feed

Researched 2026-09-27. This note uses the vocabulary in `CONTEXT.md` (Student, Work Shift,
Work Schedule Feed, Imported Work Shift). Every claim has a citation. Claims backed only by
search-result excerpts from a help center that blocked direct fetching are marked "(excerpt)".
Claims with no primary source are marked **unverified**.

## Summary

- Of the 24 scheduling products checked (leaving out the two job marketplaces), **10 (about 42%)
  document a live, per-employee ICS subscription URL**: UKG Pro WFM/Dimensions, QGenda, Amion,
  Lightning Bolt, When I Work, Deputy, 7shifts, Sling, Humanity and Connecteam.
- **The split follows the type of product.** Physician/on-call schedulers (QGenda, Amion,
  Lightning Bolt) and general hourly tools (6 of 8) publish feeds. Nurse and staff workforce
  systems mostly do not. The exception is UKG Pro WFM, and there the employer must turn the
  feature on. symplr, Epic Teamwork, Oracle Health Clairvia, ShiftWizard, Smartlinx, OnShift and
  Clairvoyant have no public documentation of an employee ICS feed.
- Per-diem marketplace apps (ShiftKey, ShiftMed, Clipboard Health) have no documented calendar
  export. Incredible Health and Vivian are hiring marketplaces, not shift schedulers.
- No vendor offers a public API scoped to one employee. The ICS URL is effectively the only
  interface an employee controls.
- The ICS hosts we could test do not send permissive CORS headers. A browser-only importer will
  not work; feeds must be fetched server-side.

## Comparison table

| System | Employee export | Live per-user secret URL | Employer must enable | Notable scope / quirks |
|---|---|---|---|---|
| UKG Pro WFM / Dimensions | ICS subscription (guided or "Copy URL") | Yes | Yes (ACP + switch) | 6-week lookahead; absences, paycodes, "On Call" tags become events |
| UKG Workforce Central (+ Advanced Scheduling) | None documented | No | n/a | unverified |
| symplr Workforce (API Healthcare/ANSOS) | One-time copy to phone calendar | No | Yes (System Std 44) | Manual export |
| QGenda | ICS subscription | Yes ("unique… specific to you") | Scheduled users only | Future + recent past weeks; all-day and timed assignments |
| Amion | ICS subscription | Yes | No (unverified) | 300 days ahead, 2 weeks back |
| Lightning Bolt (PerfectServe) | ICS subscription (URL emailed) | Yes | unverified | |
| Epic Teamwork | Outlook integration (org-level) | No | Yes | unverified details |
| Oracle Health Clairvia | Web + Cerner Staff Manager app only | No | n/a | |
| ShiftWizard (HealthStream) | None documented | unverified | unverified | |
| Smartlinx, OnShift, Clairvoyant | None documented | No | n/a | |
| ShiftKey, ShiftMed, Clipboard Health | None documented | No | n/a | In-app bookings only |
| When I Work | ICS subscription (web/iOS) | Yes (per view) | Partly (full-schedule view) | Published shifts, 1 year ahead; not on Android |
| Deputy | Webcal subscription or one-time .ics | Yes | No | Published shifts |
| 7shifts | ICS subscription | Yes (unique, not revocable per docs) | No | |
| Sling | ICS subscription (web only) | Yes (resettable) | Premium/Business plan | ±1 month; includes time off |
| Humanity (TCP) | ICS "Sync URL" per schedule | Yes | No | −1 / +6 months |
| Connecteam | ICS subscription | Yes (own shifts only) | No | Published, assigned shifts only |
| Homebase | Mobile app writes to device calendar | No | No | |
| HotSchedules (Fourth) | Google Calendar push; device calendar | No ICS URL documented | Site-dependent | Duplicate-event reports |
| Microsoft Teams Shifts | None native | No | n/a | Power Automate workarounds |

## Per-system notes

**UKG Pro WFM / Dimensions.** Employees subscribe with a generated iCalendar URL, either through
a guided flow or "Copy URL". Syncing is one-way. The system "looks forward six weeks", and the
calendar provider decides how often to refresh. Events cover shifts (label, start/end, org path),
absences, paycodes and schedule tags such as "On Call". Times are converted to the calendar's
local time. Admins must allow the "Synchronize with My Schedule" access control point and turn on
the ESS Personal Calendar Synchronization switch
([UKG help](https://sso-hlp01.gss.mykronos.com/help/en_US/oxy_ex-2/_shared/common_topics/configure_calendar_synchronization.html)).
Release 2024.R1 replaced the feature switch with that ACP
([excerpt, UKG What's New 2024.R1](https://customer2.kronos.com/support/KOL/OnlineHelp-WorkforceDimensions/en-us/Content/R9/What's%20New/R9U6_Whats_New.htm)).
Whether the URL embeds a secret token is not documented. A separate Google add-in also exists
([UKG brochure](https://d3bql97l1ytoxn.cloudfront.net/app_resources/221400/documentation/724448_en-US.pdf)).
Third parties report that "many workplaces disable it or never set it up"
([text-2-ics](https://www.text-2-ics.com/sync/ukg-kronos)). The "My Schedule" help page for the
Workforce Central generation does not mention any export
([UKG](https://communityfiles.ukg.com/support/kol/onlinehelp-workforcedimensions/en-us/Content/Employee/MySchedule.htm));
a WFC feed is **unverified**, and so is anything specific to Advanced Scheduling.

**symplr Workforce.** The only option is an employer-enabled, manual "export (copy)" of My
Schedule events to the phone calendar, controlled by System Standard 44 and off by default
([symplr config guide 2025.2](https://help.symplr.com/workforce/workforce_app/configuration_guide_-_workforce_app__symplr_workforce__2025.2.0.pdf)).
Marketing copy about syncing "to personal calendar apps" refers to the physician-scheduling
product ([symplr](https://www.symplr.com/products/symplr-workforce-suite)). No subscription URL
exists.

**QGenda.** The Sync button shows "a unique subscription URL specific to you". Only scheduled
users see it, and assignments for the future plus recent past weeks are included. QGenda asks
users to set refresh to one day and to "avoid very short refresh times"
([QGenda manual](https://sites.duke.edu/nephfellow/files/2021/06/QGenda-User-Sync-Manual-1.pdf)).
Anyone who has the link can view the schedule
([Kansas Health System](https://www.kansashealthsystem.com/-/media/project/website/pdfs-for-download/covid19/share-a-qgenda-schedule.pdf)).

**Amion.** Personal schedules sync by URL subscription, covering 300 days ahead and the two most
recent weeks; a refresh of "once every few hours" is advised
([excerpt, Amion](https://support.amion.com/hc/en-us/articles/26561852130067-Calendar-Subscriptions)).

**Lightning Bolt.** Users request a "Calendar Subscription Notice" email that contains the .ics
subscription URL
([excerpt](https://support.lightning-bolt.com/hc/en-us/articles/360044492171-How-do-I-sync-schedule-to-Outlook-);
[Google](https://support.lightning-bolt.com/hc/en-us/articles/360044491971-How-Do-I-Sync-Schedule-With-Google-Calendar-)).

**Epic Teamwork** became generally available in 2025
([Epic](https://www.epic.com/epic/post/teamwork-staff-scheduling-delivers-faster-care-coordination-and-less-administrative-work-at-health-systems-worldwide/)).
One customer's education site mentions Epic events appearing in Outlook
([U Iowa](https://epicsupport.sites.uiowa.edu/teamwork)). An employee-facing ICS feed is
**unverified**.

**Oracle Health Clairvia.** Staff use Clairvia Web or the Cerner Staff Manager app, and the
guide describes no export
([Northern Light guide](https://hi.northernlighthealth.org/Flyers/Non-Providers/Hospital-Nurse/Clairvia/General-Use-(All-Staff)/Clairvia-Clinical-Team-Scheduling-Guide.aspx)).

**ShiftWizard, Smartlinx, OnShift, Clairvoyant.** The product and app pages list viewing
schedules, swaps and time off, but no calendar export
([ShiftWizard](https://www.healthstream.com/solution/scheduling/shiftwizard-mobile-app),
[Smartlinx Go](https://www.smartlinx.com/solutions/smartlinx-go/),
[OnShift](https://www.onshift.com/products/employee-mobile-app)). Absence of a feed is
**unverified**. NurseGrid (HealthStream), a personal nurse calendar app, does offer an iCal feed
([NurseGrid](https://nursegrid.com/for-nurses/calendar/)).

**Per-diem apps.** No calendar export is documented for ShiftKey, ShiftMed or Clipboard Health
([Clipboard](https://workers.clipboardhealth.com/hc/en-us/articles/34214219385239-How-to-Use-the-Clipboard-App),
[ShiftMed](https://www.shiftmed.com/nurses/app/)); this is **unverified**. Incredible Health
places nurses in permanent jobs ([Incredible Health](https://www.incrediblehealth.com/talent)) and
Vivian is a job marketplace ([Vivian](https://www.vivian.com/)).

**When I Work.** The link comes from "Calendar Sync" on the My Schedule page, with separate links
for "Your Schedule", OpenShifts and the Entire Schedule. The feed carries published shifts up to
one year ahead. There is no sync from the Android app, and "When I Work Does Not Control Calendar
Sync Frequency"
([When I Work](https://help.wheniwork.com/articles/syncing-your-schedule-to-a-calendar-app-computer/)).
One implication: a Student could paste an OpenShifts or Entire Schedule URL, and the importer
would then treat unassigned shifts as work.

**Deputy.** Employees choose a Webcal link for ongoing sync or an .ics download of current shifts
only ([excerpt, Deputy](https://help.deputy.com/hc/en-au/articles/4688796818703-Syncing-your-Deputy-schedule-with-your-own-calendar-application)).

**7shifts.** Each employee gets a personal iCal URL. Links are "unique and must not be shared" and
access "cannot be revoked", and calendars typically refresh every 2–12 hours
([excerpt, 7shifts](https://kb.7shifts.com/hc/en-us/articles/4861793532691-Sync-Your-7shifts-Schedule-with-Google-and-Apple-Calendar)).

**Sling.** The unique URL is generated on the web only and can be reset or disabled. It covers one
month back and one month ahead, includes time-off events, and requires a Premium or Business plan
([Sling](https://support.getsling.com/en/articles/6062972-calendar-sync)).

**Humanity.** An RSS-style "Sync URL" is generated per schedule and covers one month back and six
months ahead ([excerpt, Humanity](https://helpcenter.humanity.com/en/articles/3062271-sync-schedule)).

**Connecteam.** The feed carries only published shifts assigned to the user. Rejecting a shift
does not remove it from Google Calendar, and changes take hours to 24 hours to appear
([Connecteam FAQ](https://help.connecteam.com/en/articles/8057630-calendar-app-sync-faqs-for-managers)).

**Homebase.** The mobile app is granted calendar access and writes shifts to the device calendar
([excerpt, Homebase](https://support.joinhomebase.com/hc/en-us/articles/360022479511-Calendar-Sync)).

**HotSchedules.** Shifts sync to Google Calendar from the web or to the native calendar from the
app. Availability depends on site setup
([excerpt, HotSchedules](https://help.hotschedules.com/hc/en-us/articles/215566067-HS-Settings-Google-Calendar-and-Mobile-Calendar-Sync)),
and users have reported not finding an iCal URL
([community](https://help.hotschedules.com/hc/en-us/community/posts/115000927052-iCal-calendar-sync)).

**Microsoft Teams Shifts.** When asked about .ics export, Microsoft support staff did not describe
one ([Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/5573409/how-do-i-export-my-teams-shift-calender-as-a-ics-f)).
Syncing to Outlook requires Power Automate
([SharePains](https://sharepains.com/2024/03/07/synchronise-microsoft-shifts-outlook-calendars/)).

## CORS: can a browser app fetch these feeds directly?

Generally no. Tests run on 2026-09-27 with `curl -H "Origin: https://example.com"` found:

- Google's public holiday ICS returned `text/calendar` with **no** `Access-Control-Allow-Origin`.
- QGenda `app.qgenda.com/ical` (dummy key) and When I Work (dummy path) returned no ACAO.
- Outlook published-calendar URLs (dummy IDs) redirected with no ACAO.
- iCloud published calendars returned only `access-control-expose-headers`.
- Amion reflected the origin with credentials, but only on an HTML error page. This is
  inconclusive.

Dummy-token probes are weak evidence. FullCalendar users report "No 'Access-Control-Allow-Origin' header" when loading remote ICS feeds
([FullCalendar #7476](https://github.com/fullcalendar/fullcalendar/issues/7476)). **Conclusion:
fetch feeds server-side** (or from native apps, which CORS does not affect). A server-side fetch
also avoids exposing the secret URL to third-party proxies.

## Fallbacks when there is no feed

1. **Push into Google or Outlook, then use that calendar's secret ICS.** Some vendors write into
   Google or the device calendar (HotSchedules, UKG Google add-in, symplr, Homebase). Google shows
   every owned calendar's "Secret address in iCal format", which can be reset; Workspace admins
   may hide it ([Google](https://support.google.com/calendar/answer/37648?hl=en)). Outlook.com can
   publish a calendar as a read-only ICS link and unpublish it later
   ([Microsoft](https://support.microsoft.com/en-us/outlook/share-your-calendar-in-outlook-com)).
   Caveats: the vendor must push into a **dedicated** calendar, because a primary calendar's
   address would leak personal events, and `CONTEXT.md` says personal calendars are not Work
   Schedule Feeds. Latency also stacks. Google refreshes URL subscriptions roughly every 8–24
   hours with no manual refresh
   ([Google Community](https://support.google.com/calendar/thread/12658899/google-calendar-does-not-sync-url-linked-calendars-within-12-hours-as-stated?hl=en)),
   and Outlook.com updates about every 3 hours but "can take more than 24 hours"
   ([Microsoft](https://support.microsoft.com/en-us/office/import-or-subscribe-to-a-calendar-in-outlook-com-or-outlook-on-the-web-cff1429c-5af6-41ec-a5b4-74f2c278e98c)).
2. **One-time .ics import** (Deputy download, Teams via Outlook). This is a snapshot, not a feed.
3. **Screenshot/PDF to events** via roster scanners
   ([Shift2Cal](https://play.google.com/store/apps/details?id=com.loudsrl.shift2calendar&hl=en_GB));
   for us, manual Work Shift entry covers this.

## Implications for a generic Work Schedule Feed importer

- **Fetch server-side, on our own schedule.** Refresh interval is always left to the subscriber.
  QGenda asks for daily refresh, and 2–12 hours is typical, so the Student should see when the
  feed was last fetched. Persist the URL as a secret: treat it like a credential, never log it,
  and let the Student replace it, since Sling and Google URLs can be reset and 7shifts links
  cannot be revoked.
- **Accept `webcal://`** by rewriting it to `https://`
  ([Webcal](https://en.wikipedia.org/wiki/Webcal)).
- **Match by `UID` only when `UID`s are stable.** RFC 5545 requires `UID` to be persistent and
  unique ([RFC 5545 §3.8.4.7](https://www.rfc-editor.org/rfc/rfc5545#section-3.8.4.7)). No
  vendor above documents that its UIDs are stable, so this is **unverified** per vendor; ER
  Schedule's are. Tolerate UIDs that change when a shift is edited: a delete plus an add must
  not lose Student-visible state, and duplicates have been reported (HotSchedules).
- **Removal semantics must respect the feed's window.** Windows vary: UKG 6 weeks ahead; Sling
  ±1 month; Humanity −1/+6 months; Amion −2 weeks/+300 days; When I Work up to 1 year. A shift
  that falls outside the window is not a cancellation. Only delete Imported Work Shifts that
  fall *within* the span the current fetch covers. Derive that span conservatively, because
  vendors do not state it in the feed.
- **Time handling.** Expect UTC, `TZID`-qualified local times, and floating times. `VALUE=DATE`
  all-day events (ER Schedule codes, QGenda all-day assignments) need a policy, such as marking
  them as all-day or code-only work markers.
- **Non-shift events will appear.** Time off (Sling), absences, paycodes and "On Call" tags (UKG)
  all show up as events. `CONTEXT.md` says every event is work, so these create false Work
  Shifts and false Schedule Conflicts. Consider showing `SUMMARY` verbatim and letting the
  Student hide an event, which is not the same as editing it.
- **Feeds can be over-scoped.** "Entire Schedule" or OpenShifts URLs (When I Work, Humanity) can
  flood the calendar; sanity-check the first import (e.g. many overlapping events per day).
- **Fields to rely on:** `DTSTART`, `DTEND` (or `DURATION`), `SUMMARY`, and `UID`, which is
  usually present. Treat `LOCATION`, `DESCRIPTION` (Connecteam omits notes), `STATUS`,
  `SEQUENCE` and `RRULE` as optional; Connecteam does not emit recurring shifts as recurring.
- **Onboarding copy** should say that the Student's employer may need to turn the feature on
  (UKG, symplr, HotSchedules), and that feeds usually have to be obtained from the web app
  rather than the mobile app (QGenda, Sling, 7shifts, When I Work on Android).
