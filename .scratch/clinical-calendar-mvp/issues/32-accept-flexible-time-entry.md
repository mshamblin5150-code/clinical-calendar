# Accept Flexible Time Entry

Type: task
Status: resolved
Blocked by: none

## What's wrong

Time fields require colon-formatted military values, and 12-hour mode does not provide an AM/PM editing layout or reliably refresh template times.

## What I expected

All time fields accept `0700`, `07:00`, or `1400`; military mode normalizes to `HH:MM`, while 12-hour mode displays a 12-hour value with AM/PM and still accepts military input such as `1400` as 2:00 PM. Durations and template summaries recalculate automatically.

## Answer

Shared flexible time fields now normalize colonless military input and provide AM/PM controls in 12-hour mode. Rendered QA verified `1400` becomes `2:00 PM`, `0700` becomes `07:00`, templates and calculated hours refresh, calendar time labels follow the preference, and changing Commitment resets the batch to the selected template times.
