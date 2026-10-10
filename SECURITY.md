# Security policy

## Lab use only

The included PowerShell HTTP listener is a lightweight recovery utility. Run it only on an isolated administrative network or lab VLAN. Do not expose it to the Internet.

## Defaults

- Uploads are disabled by default.
- Path traversal attempts are rejected.
- No authentication or TLS is provided.
- The listener binds to all interfaces through `http://+:PORT/`.

## Required controls

- Use host and network firewalls to restrict access to the phone network and administrative hosts.
- Stop the listener after the recovery event.
- Do not store Lens credentials, user passwords, pairing codes, phone numbers, or tenant provisioning URLs in Git.
- Do not commit firmware binaries unless redistribution is explicitly permitted.
- Rotate any credential accidentally exposed in logs, screenshots, commits, issues, or pull requests.
- Review Git history, not just the current tree, before publishing.

## Reporting

Use a private security channel maintained by the repository owner. Do not open a public issue containing credentials, tenant identifiers, MAC addresses, private IPs, or production logs.
