# Firmware directory

Firmware binaries are intentionally excluded from this repository.

## Why

- Firmware licensing and redistribution rights vary.
- A model-correct image is required; an incorrect image can make recovery harder.
- Hardware revision, current updater, application version, and supported upgrade path matter.

## Before using an image

- Obtain the image from an authorized vendor/support source.
- Verify the exact phone model and assembly number.
- Verify the publisher's checksum or signature when available.
- Record the local SHA-256 hash.
- Pilot on one lab phone.
- Never interrupt power during programming or extraction.

The validated VVX 411 test used a container named `3111-48450-001.sip.ld`, but this repository does not provide or license that file.
