# Recovery and Teams SIP Gateway Runbook

## 1. Scope

This runbook documents a completed VVX 411 recovery and onboarding path plus companion VVX 300 testing. It is intended for administrators who own the devices, tenant, network, firmware rights, and Teams configuration.

## 2. Validated version path

| Stage | UC Software | Updater | Result |
|---|---:|---:|---|
| Initial | 5.5.1.11526 | 5.7.1.13261 | Poly ZTP failed with TLS protocol-version errors |
| Manual bridge | 5.6.0.17325 | 5.8.0.19248 | Hosted Poly update became usable |
| Final | 6.3.1.13775 | 6.3.1.4633 | Lens, Teams SIP Gateway, Healthy status, and calling validated |

Do not call the bridge “UC firmware 5.8.” The `5.8.0.19248` value was the updater component.

## 3. Decision tree

### Use the hosted updater directly when

- The phone reaches Poly hosted software update.
- No TLS protocol-version error appears.
- A compatible hosted release is offered.

### Use the local bridge when

- The phone repeatedly reports a TLS protocol-version failure against Poly ZTP.
- DNS, gateway, and Internet access are otherwise functioning.
- A model-correct, authorized intermediate image is available.

### Recover the application separately when

- The display says `Application not present`.
- The updater shell runs, but the SIP application is missing or corrupt.

## 4. Local recovery server

### 4.1 Directory layout

```text
C:\polyftp\
  polyhttpserver.ps1
  001122aabbcc.cfg
  <model-correct-firmware>.sip.ld
```

Use the actual lower-case MAC address without separators for the configuration filename.

### 4.2 Configuration example

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<APPLICATION APP_FILE_PATH="<model-correct-firmware>.sip.ld" />
```

### 4.3 Start the server

```powershell
Set-ExecutionPolicy RemoteSigned -Scope Process
.\scripts\polyhttpserver.ps1 -Root C:\polyftp -Port 8080
```

The listener logs the source IP, method, path, result, and byte count. Uploads are disabled unless `-AllowUploads` is explicitly supplied.

### 4.4 Validate before touching the phone

```powershell
Test-NetConnection 192.0.2.10 -Port 8080
curl.exe http://192.0.2.10:8080/001122aabbcc.cfg
```

Expected listener output includes `FOUND` and the correct byte size.

### 4.5 Configure the VVX

- Boot Server: `Static`
- Server Type: `HTTP`
- Server Address: `<recovery-server-ip>:8080`
- Username and password: blank for the isolated lab listener

Save and reboot, or invoke Update Configuration.

### 4.6 Success indicators

- MAC-specific configuration is requested.
- The phone requests the `.sip.ld` image.
- Boot log reports `Recognized container image`.
- Boot log reports `Good image signature`.
- Updater programming completes.
- Application extraction reports `Finished extracting application files (OK)`.
- Boot log reports `Finished software update` and `Provisioning succeeded`.

An HTTP write-aborted message does not by itself prove failure. Use the phone boot log and resulting versions as the authoritative indicators.

## 5. Complete the hosted Poly update

After the bridge, use the phone's hosted software upgrade workflow. Expect staged behavior:

1. Download new updater.
2. Save updater.
3. Reboot.
4. Download new application.
5. Check and extract application files.
6. Reboot again.

Do not interrupt power during programming, extraction, or flash synchronization.

## 6. Enroll in HP Poly Lens

1. Enable Device Provisioning in the Poly Lens account.
2. Obtain the tenant-specific provisioning URL and credentials.
3. Enter them in the phone's provisioning-server settings.
4. Save and reboot.
5. Verify the device appears as `Provisioned` or `Provisioned (Active)`.
6. Verify current firmware, serial/MAC, private IP, and recent provisioning sync.
7. In logs, confirm the tenant Lens host and `CLOUD STATUS : ONLINE`.

Do not publish tenant-specific provisioning URLs or credentials.

## 7. Enable Lens Assisted Provisioning

In Poly Lens:

1. Open **Manage > Inventory**.
2. Select the provisioned voice device.
3. Open **Settings > Integrations > Microsoft Teams**.
4. Enable **Lens Assisted Provisioning Feature**.
5. Select the SIP Gateway region and language.
6. Apply the change and reboot.

Changing the integration settings or using Clear Cache restarts the relationship, creates a new device identity/provisioning URL, and can sign the user out.

Expected device indicators:

- Base Profile returns to `Generic`.
- Teams logo appears.
- Phone directs the user to `aka.ms/siplogin`.

## 8. Enable SIP devices in Teams

In Teams Admin Center, edit the calling policy assigned to the user and enable:

```text
SIP devices can be used for calls
```

If disabled, the pairing portal can report:

```text
User does not have AllowSIPDevicesCalling policy set.
```

## 9. Pair and validate

1. Browse to `aka.ms/siplogin`.
2. Enter the pair code shown on the phone.
3. Sign in as the intended Teams Phone user.
4. Confirm authorization succeeded.
5. Allow the phone to reboot and finish provisioning.
6. In Teams Admin Center, confirm the device under **Teams devices > SIP devices**.
7. Confirm the status transitions to `Healthy`.
8. Test inbound and outbound calls.

Recommended functional testing:

- Hold and resume
- Mute and unmute
- Blind transfer
- Consultative transfer
- Voicemail and message-waiting indicator
- Caller ID
- DTMF/IVR
- Emergency-calling design and location behavior

## 10. Known dead ends

### Skype for Business Web Sign-In

The legacy phone path presented User Credentials, Via PC/BToE, and Web Sign-In. The Web Sign-In request used a legacy Polycom Skype for Business application and returned `AADSTS65006`. That path is not required for the working Teams SIP Gateway deployment.

### Assigning users to the Poly Lens enterprise app

Poly Lens access and the legacy Skype-certified-phone application are separate. Assigning a user to the Poly Lens enterprise application does not repair the legacy SfB OAuth request.

### Teams “Provision devices” verification code

The Teams SIP Gateway pairing code displayed by the Lens-assisted phone and entered at `aka.ms/siplogin` is the relevant workflow for this implementation.

## 11. Troubleshooting map

| Symptom | Meaning | Action |
|---|---|---|
| `tlsv1 alert protocol version` | Firmware/updater cannot negotiate with current cloud service | Use an authorized local bridge image |
| `Application not present` | Missing/corrupt SIP application | Recover with a correct model-specific image |
| `AADSTS65006` in SfB Web Sign-In | Legacy SfB app path | Use Generic profile and Lens Assisted Provisioning |
| `AllowSIPDevicesCalling` unset | Teams calling policy blocks SIP devices | Enable SIP devices in the user policy |
| Lens reports `CLOUD STATUS : ONLINE` | Lens cloud connector is operating | Continue with Teams integration |
| Teams shows device Offline after pairing | Device object exists, registration has not completed | Wait for reboot/provisioning and inspect current logs |
| Teams shows Healthy and calls work | Deployment validated | Record state and proceed with controlled rollout |

## 12. Production checklist

- [ ] Record exact model, assembly, MAC, starting UC version, and updater version.
- [ ] Pilot one phone per model/hardware revision.
- [ ] Confirm DHCP, DNS, gateway, NTP, and outbound firewall access.
- [ ] Use only authorized model-correct firmware.
- [ ] Capture bridge boot logs and final versions.
- [ ] Assign the device to the correct Lens account, site, group, and policy.
- [ ] Enable Lens Assisted Provisioning at the narrowest appropriate scope.
- [ ] Enable SIP devices in the correct Teams calling policy.
- [ ] Pair and verify Healthy status.
- [ ] Validate call functions and emergency-calling requirements.
- [ ] Preserve scripts, checksums, logs, and documentation in a restricted IT repository.
