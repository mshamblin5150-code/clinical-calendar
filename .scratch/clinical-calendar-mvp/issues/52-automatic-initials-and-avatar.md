# Automatic Initials and Optional Avatar

Type: task
Status: resolved
Blocked by: none

## Problem

The Student Profile asks the student to maintain initials manually and provides no optional photo/avatar.

## Acceptance criteria

- Initials derive automatically from the Display name.
- The profile accepts an optional image file and previews it.
- The uploaded image replaces initials in the header avatar; initials remain the fallback.
- The student can remove or replace the image.
- Help explains automatic initials, the avatar fallback, and prototype-only storage.
- Controls remain readable on phone and desktop layouts.

## Resolution

Student Profile now derives read-only initials automatically from the first two parts of the Display name. Students can optionally choose, preview, replace, or remove a photo/avatar; the header shows the image when present and falls back to initials when absent. Help identifies this behavior and the prototype's session-only image storage.
