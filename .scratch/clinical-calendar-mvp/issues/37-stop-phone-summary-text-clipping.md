# Stop Phone Summary Text Clipping

Type: task
Status: resolved
Blocked by: none

## What's wrong

The phone planning summary enforces a 58% maximum width, hidden overflow, and no wrapping, which cuts off status text such as `Ready`.

## What I expected

The summary uses the available width and wraps complete text onto another line before clipping, while the chevron and Review button remain fully visible.

## Answer

The phone summary copy now flexes and wraps with visible overflow instead of using a 58% clipped single line. Rendered QA verified `Ready` remains visible at both 390px and 320px viewports, the chevron and Review button retain their full width, and client/scroll widths match. The obsolete global 320px minimum width was also removed to prevent scrollbar-induced overflow at the smallest supported viewport.
