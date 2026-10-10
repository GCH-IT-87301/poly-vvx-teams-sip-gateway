# Contributing

Contributions are welcome when they improve safety, clarity, repeatability, or model coverage.

## Please include

- Exact phone model and assembly number
- Starting UC software and updater versions
- Final UC software and updater versions
- Whether hosted update worked before any local bridge
- Sanitized log excerpts
- Validation performed after onboarding

## Do not include

- Firmware binaries without redistribution rights
- Tenant-specific Poly Lens URLs or credentials
- Pairing codes, passwords, phone numbers, private IPs, or unredacted MAC addresses
- Production logs containing personal data

## Pull-request expectations

- Keep model-specific observations labeled as observations, not universal rules.
- Link to official Microsoft or HP Poly documentation when changing supported procedures.
- Test PowerShell changes with PSScriptAnalyzer when available.
- Preserve secure defaults, especially disabled uploads and path-traversal protection.
