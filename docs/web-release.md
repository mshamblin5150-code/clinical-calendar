# Web Release

Clinical Calendar is publicly hosted at
<https://mshamblin5150-code.github.io/clinical-calendar/>. Public hosting makes
the application bundle downloadable by anyone; it does not make a Student's
calendar public. The bundle contains only a Supabase publishable key. Sign-in
and row-level security protect synchronized data.

> [!IMPORTANT]
> Before sharing the web-app link with anyone outside the Supabase
> organization, verify that custom SMTP is enabled, the sender and a modest
> project email cap are recorded on
> [issue #241](https://github.com/mshamblin5150-code/clinical-calendar/issues/241)
> without exposing credentials, and the owning release issue records a passed
> external-address delivery check. Do not fall back to the built-in Supabase
> sender. Repeat the delivery check before sharing a different deployment or
> after changing the sender, SMTP provider, or email rate cap.

## One-time GitHub configuration

In **Settings -> Pages -> Build and deployment**, set **Source** to **GitHub
Actions**. The resulting Pages configuration has build type `workflow`, uses
the repository's `main` branch, and enforces HTTPS.

Create an environment named `github-pages`. Allow deployments only from the
`main` branch and configure these values:

| Kind | Name | Value |
| --- | --- | --- |
| Variable | `CLINICAL_CALENDAR_ENVIRONMENT` | `private-release` |
| Variable | `CLINICAL_CALENDAR_SUPABASE_URL` | `https://lembezcrpyyzmimsreiz.supabase.co` |
| Secret | `CLINICAL_CALENDAR_SUPABASE_PUBLISHABLE_KEY` | The Clinical Calendar project's Supabase publishable key, or its legacy `anon` JWT |

Never use a Supabase secret or service-role key. The release wrapper rejects
missing values, non-HTTPS project URLs, privileged JWT roles, and malformed
client keys. Keep the publishable key in the environment secret even though it
is intentionally present in the downloadable client bundle; its safety relies
on row-level security, not secrecy.

The workflow needs the repository permissions declared in
`.github/workflows/pages.yml`: `contents: read`, `pages: write`, and
`id-token: write`. No signing key, database key, backup passphrase, access
token, refresh token, or test credential belongs in the environment or bundle.

## Automatic deployment

Every push to `main` starts the `Quality` workflow. After that exact `main`
commit passes Quality, `Deploy to GitHub Pages` checks out the successful
commit, runs `tool/web/build_pages.ps1`, uploads
`apps/clinical_calendar/build/web`, and deploys it through the official Pages
actions. Failed Quality runs, pull-request Quality runs, and successful runs
from branches other than `main` do not deploy. Deployments queue instead of
cancelling an in-progress deployment.

The release wrapper uses Flutter 3.44.8 and builds with base href
`/clinical-calendar/`. It supplies the three environment values above and the
numeric build from `apps/clinical_calendar/pubspec.yaml`. The build fails unless
that number matches `apps/clinical_calendar/web/build-id.json`.

### Minimum synchronization build

[ADR-0002](adr/0002-older-builds-cannot-overwrite-newer-synced-data.md)
requires any merge that changes the shape of a synchronized record to raise
the server's `clinical_calendar_sync.sync_configuration.minimum_sync_build` in
the same change. Before such a migration is deployed:

1. Increase the numeric build suffix in
   `apps/clinical_calendar/pubspec.yaml`.
2. Put the same number in
   `apps/clinical_calendar/web/build-id.json`.
3. Set `minimum_sync_build` to the first build compatible with the changed
   record shape—normally the candidate build—in the accompanying migration or
   configuration change. It must not exceed the build being deployed.
4. Run the full quality gate before merge.

Clients below the minimum may pull, but their pushes are held until they are
updated. A web tab checks the uncached `build-id.json` when opened or brought
back to the foreground and reloads only after its in-memory outbox is empty.
Do not raise the server minimum ahead of an available compatible build.

## Reproduce or repair a deployment

1. From a clean checkout of `main`, verify the Pages source, environment branch
   rule, variables, and secret described above.
2. Confirm `pubspec.yaml` and `web/build-id.json` carry the same positive build
   number. If synchronized record shape changed, also confirm the minimum-build
   migration follows the rule above.
3. Run the repository release contracts and full quality gate:

   ```powershell
   ./tool/web/pages_workflow_contract_test.ps1
   ./tool/web/build_pages_contract_test.ps1
   dart run tool/quality.dart
   ```

4. Merge the reviewed commit to `main`. In **Actions**, confirm `Quality`
   succeeds for that commit and the following `Deploy to GitHub Pages` run
   deploys the same commit.
5. Open the production URL, confirm the connection is HTTPS, then open
   `/clinical-calendar/build-id.json` and confirm its `build_number` matches the
   candidate.
6. Exercise the web section of
   [the release security checklist](release-security-checklist.md) with
   invented, non-patient data. Record the commit, workflow run URLs, browser,
   date, and results on the owning release issue. Stop sharing or release work
   if any check fails.

For an intentional rerun of the current `main` commit, use **Actions -> Deploy
to GitHub Pages -> Run workflow** and select `main`, or run:

```powershell
gh workflow run pages.yml --ref main
```

Manual dispatch is a recovery mechanism, not a way to deploy an unreviewed
branch. Verify the run's commit before accepting it.

## Measured bundle and load size

Issue #239 measured the deployed merge commit
`99bfd46b0923fc22993ee0b3846a3889fea5481b` in Pages run
[`36342338555`](https://github.com/mshamblin5150-code/clinical-calendar/actions/runs/36342338555)
on 2026-09-27:

- `build/web`: 75,358,204 bytes (71.87 MiB) across 91 files.
- `main.dart.js`: 4,063,938 bytes (3.88 MiB).
- Compressed GitHub Pages artifact: 44,535,016 bytes (42.47 MiB).
- Cold first load under Lighthouse simulated mobile throttling: 3,219,664
  transferred bytes (3.07 MiB) across 12 requests.
- The same run measured FCP at 1,274 ms, Speed Index at 8,032 ms, and total
  blocking time at 1,410 ms; the console-error audit passed. Flutter canvas
  rendering did not yield a dependable LCP, so no LCP is reported.

Treat these as the baseline for the measured commit, not a permanent size
budget. Re-measure after material framework, asset, or bundle changes.
