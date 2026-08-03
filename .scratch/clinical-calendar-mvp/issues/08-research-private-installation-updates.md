# Research Private Installation and Updates

Type: research
Status: resolved
Blocked by: 01

## Question

What exact build, signing, private-installation, and update path should the Flutter MVP use on the Student's Windows machine, iPhone, and Android tablet, including Apple hardware or developer-account requirements, safe sideloading or beta-distribution options, repeatable builds, and the later transition to public distribution?

## Comments

## Answer

Use a repeatable privately installable artifact per target platform: a signed Windows release, a signed Android APK, and a provisioned iPhone archive built with Xcode on macOS. Development/ad hoc provisioning proves the physical iPhone gate; TestFlight is the preferred repeatable private beta path. Public store submission remains outside the MVP. Exact pinned toolchains, signing prerequisites, installation, upgrade, and recovery steps are verified first by ticket 58 and completed by platform tickets 85-87 under [`spec.md`](../spec.md#10-packaging-and-installation-gate).
