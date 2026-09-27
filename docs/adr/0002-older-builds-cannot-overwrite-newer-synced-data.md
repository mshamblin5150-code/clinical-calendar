---
status: accepted
---

# Older builds cannot overwrite newer synced data

The web app goes live on every merge to `main`, while a native install keeps whatever private build the Student last installed. The sync envelope is fixed at `schema_version: 1` and the server validates only the envelope, so a newer build can write records an older build does not fully understand, and the older build could drop unknown fields when it edits and re-pushes them. **Each client sends its build number when it synchronizes, and the server holds a minimum build that is raised only when a merge changes the shape of synced data. A client below the minimum can still pull, but its pushes are held and it shows "Update this app to keep syncing – your changes are safe on this device."** Grilled in #230.

## Considered options

- **Deploy web only in step with the Android private release.** Rejected by the Student, who wants web to be the always-current build.
- **Accept the risk and rely on the Student to update the tablet before opening it.** Rejected, because memory fails during clinical weeks and the failure is silent field loss.
- **Require every change to synced data to be additive, and older builds to preserve unknown fields.** Rejected for now. It is the more elegant rule, but it puts a permanent compatibility obligation on every future feature ticket, and it needs proof that current builds already preserve unknown fields.

## Consequences

- A native client below the minimum keeps its held changes in its encrypted local outbox until it is updated, so nothing is lost.
- A web tab left open across a deploy is an older build too. Web checks for a new version when it is opened or brought back to the front, and reloads itself once nothing is unsent.
- Any merge that changes the shape of a synced record must raise the minimum build in the same change.
