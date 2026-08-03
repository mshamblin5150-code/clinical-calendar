# Preserve Contextual Modal Navigation

Type: task
Status: resolved
Blocked by: none

## What's wrong

Student profile and Notifications do not return to the application menu when launched from it, while direct-launch surfaces should continue to close without an unnecessary Back action.

## What I expected

Menu-launched management surfaces show Back and return to the menu; surfaces launched directly from the header or phone navigation retain close-only behavior.

## Answer

Modal state now carries an explicit Back destination. Rendered QA verified menu-launched Student profile and Notifications show Back and return to Clinical Calendar, while direct header/phone launches show Close without Back.
