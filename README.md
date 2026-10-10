# Poly VVX to Microsoft Teams SIP Gateway

A field-tested recovery and onboarding workflow for selected legacy Poly VVX phones that are too old to reach modern Poly cloud services, followed by HP Poly Lens Assisted Provisioning and Microsoft Teams SIP Gateway enrollment.

> **Validated result:** A VVX 411 starting on UC Software `5.5.1.11526` was manually bridged to UC Software `5.6.0.17325` with Updater `5.8.0.19248`, upgraded through Poly hosted services to UC Software `6.3.1.13775`, enrolled in Poly Lens, paired to Teams SIP Gateway, displayed as Healthy in Teams Admin Center, and successfully placed a call.

## What this repository includes

- A hardened lab HTTP listener for serving VVX configuration and firmware files
- Generic MAC-specific configuration templates
- A complete recovery and Teams SIP Gateway runbook
- Troubleshooting notes for TLS failures, missing applications, Poly Lens, and Teams policy errors
- No firmware binaries, credentials, tenant URLs, device codes, phone numbers, or production secrets

## The working architecture

```text
Legacy Poly VVX
  -> local HTTP firmware bridge, only if hosted update fails because of old TLS
  -> Poly hosted software update
  -> Poly Lens Device Provisioning
  -> Lens Assisted Provisioning for Microsoft Teams SIP Gateway
  -> Teams calling policy allows SIP devices
  -> pair at aka.ms/siplogin
  -> Healthy Teams SIP endpoint
```

## Important firmware distinction

The successful manual bridge was **not UC Software 5.8**. The bridge container produced:

- UC Software: `5.6.0.17325`
- Updater: `5.8.0.19248`

That combination was sufficient in this test to reach the hosted upgrade path. It is a validated observation for one VVX 411, not a universal minimum for every model or hardware revision.

## Quick start

1. Read [`docs/runbook.md`](docs/runbook.md).
2. Put an authorized, model-correct firmware image in a local recovery directory. Do not commit the binary.
3. Copy and customize [`examples/000000000000.cfg.example`](examples/000000000000.cfg.example) or [`examples/MAC.cfg.example`](examples/MAC.cfg.example).
4. Run the lab server:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\scripts\polyhttpserver.ps1 -Root C:\polyftp -Port 8080
```

5. Validate from another host:

```powershell
Test-NetConnection 192.0.2.10 -Port 8080
curl.exe http://192.0.2.10:8080/001122aabbcc.cfg
```

`192.0.2.10` is a documentation address. Replace it with the recovery server's actual private address.

## Supported path versus legacy dead end

The successful deployment used:

- Base Profile: **Generic**
- Poly Lens: **Provisioned** or **Provisioned (Active)**
- Poly Lens: **Lens Assisted Provisioning Feature** enabled
- Teams: **SIP devices can be used for calls** enabled
- Sign-in: **aka.ms/siplogin**

The unsuccessful path used the phone's Skype for Business profile and legacy Web Sign-In, which produced `AADSTS65006`. That is not the Teams SIP Gateway onboarding path documented here.

## Security

The included HTTP listener is for an isolated recovery network or lab VLAN. It is not an Internet-facing web server. Review [`SECURITY.md`](SECURITY.md) before use.

## Firmware and trademarks

Firmware is not included. Obtain firmware from an authorized vendor or support channel and comply with the applicable license. Microsoft, Teams, Poly, Polycom, VVX, HP, and Poly Lens are trademarks of their respective owners. This community documentation is not affiliated with or endorsed by Microsoft nor HP nor Poly/Polycom.

## Official references

- [Microsoft: Configure SIP Gateway](https://learn.microsoft.com/en-us/microsoftteams/devices/sip-gateway-configure)
- [Microsoft: Plan for SIP Gateway](https://learn.microsoft.com/en-us/microsoftteams/devices/sip-gateway-plan)
- [Microsoft: Troubleshoot SIP Gateway](https://learn.microsoft.com/en-us/troubleshoot/microsoftteams/phone-system/sip-gateway-issues)
- [HP Poly Lens: Microsoft Teams Integration](https://info.lens.poly.com/docs/policy/Lens%20Assisted%20Provisioning/integration-ms-teams)

## Repository status

Initial field-tested release. Before broad rollout, validate each model and hardware revision with a pilot device.
