# Tests

Recommended local checks:

```powershell
# Syntax check
$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
  "$PWD\scripts\polyhttpserver.ps1",
  [ref]$tokens,
  [ref]$errors
) | Out-Null
$errors

# Optional style analysis
Invoke-ScriptAnalyzer -Path .\scripts\polyhttpserver.ps1 -Recurse
```

Start the listener on a lab host and verify GET, HEAD, missing-file 404, rejected PUT, and path-traversal rejection before use with a phone.
