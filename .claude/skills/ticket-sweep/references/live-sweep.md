# Live sweep collection

Use this branch only for a live sweep. Keep all collected material private.

## Tickets

1. Select the existing Chrome tab for the deployed Clinical Calendar web app.
   If it is not signed in as a Student with the Maintainer grant, stop and ask
   the Maintainer to sign in; do not handle credentials.
2. Open the app menu and choose **Tickets** under the Maintainer surface.
3. Inventory the whole list before opening details. Include every card marked
   Sent, Reopened, or New reply. Also include an open Ticket when the
   Maintainer explicitly supplies the public GitHub issue URL paired with it.
   The app does not store issue links, so do not infer a pairing. Scroll until
   the list is exhausted.
4. Open each included Ticket and record its kind, state, text, private thread,
   question count, and attached context: screen, Month, build, refusal codes,
   recent actions, and device. Device is investigation context only and cannot
   enter a draft.
5. Investigate the attached screen and identifiers only as far as the
   Maintainer surface permits. The Maintainer grant does not allow reading the
   sender's calendar, Preceptors, or sync data. Record that boundary rather
   than replacing app evidence with a database query or direct API call.

Opening a Sent Ticket marks it Seen. Keep it in the current working set.

## Evidence packet

Give one packet to one investigator. It contains:

- a local Ticket key used only to pair the response;
- all Ticket and thread facts from the app;
- attached screen, build, refusal-code, and recent-action facts;
- a public GitHub issue URL explicitly paired by the Maintainer, if any; and
- the instruction to inspect repository code and return exactly one draft.

Do not persist packets to the repository or shell history.
