# Implement Passwordless Identity and Connected Devices

Type: task
Status: open
Blocked by: 59, 69, 77, 78

## Objective

Implement passwordless email identity, secure sessions, email change, Connected Devices, revocation, and device-local sign-out.

## Acceptance criteria

- Initial setup and new-device sign-in use an emailed one-time code without requiring a password or Google account.
- Session credentials reside only in platform secure credential storage and support offline application use after initial authentication.
- Email change requires verification of the new address from a currently signed-in device.
- Connected Devices shows device name, platform, and last synchronization time.
- Revoking a device blocks its future server access without claiming to erase an offline local copy.
- Sign Out and Remove This Device's Copy reports pending changes, requires explicit confirmation, and removes only that device's local data.
- Authentication and RLS integration tests cover expired codes, token refresh, revoked devices, offline launch, and cross-Student isolation.

