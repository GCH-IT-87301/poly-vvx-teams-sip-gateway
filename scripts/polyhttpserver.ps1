[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Root = 'C:\polyftp',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 65535)]
    [int]$Port = 8080,

    [Parameter(Mandatory = $false)]
    [switch]$AllowUploads
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$resolvedRoot = [System.IO.Path]::GetFullPath($Root)
if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
    throw "Root directory does not exist: $resolvedRoot"
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()

Write-Host "Serving $resolvedRoot on port $Port" -ForegroundColor Green
Write-Host "Uploads enabled: $($AllowUploads.IsPresent)" -ForegroundColor DarkGray
Write-Host 'Press Ctrl+C to stop.' -ForegroundColor DarkGray

try {
    while ($listener.IsListening) {
        $context = $null
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            $method = $request.HttpMethod.ToUpperInvariant()
            $source = $request.RemoteEndPoint.Address.ToString()
            $relativePath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath).TrimStart('/')

            if ([string]::IsNullOrWhiteSpace($relativePath)) {
                $response.StatusCode = 400
                $response.Close()
                continue
            }

            $candidate = [System.IO.Path]::GetFullPath((Join-Path $resolvedRoot $relativePath))
            $rootPrefix = $resolvedRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
            if (-not $candidate.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-Host "BLOCKED traversal attempt from ${source}: /$relativePath" -ForegroundColor Red
                $response.StatusCode = 403
                $response.Close()
                continue
            }

            Write-Host ''
            Write-Host "SOURCE:  $source" -ForegroundColor DarkGray
            Write-Host "METHOD:  $method" -ForegroundColor Yellow
            Write-Host "REQUEST: /$relativePath" -ForegroundColor Yellow
            Write-Host "FILE:    $candidate" -ForegroundColor Cyan

            switch ($method) {
                'PUT' {
                    if (-not $AllowUploads) {
                        Write-Host 'UPLOAD REJECTED: start with -AllowUploads to accept PUT' -ForegroundColor Red
                        $response.StatusCode = 405
                        $response.Close()
                        continue
                    }
                    $parent = Split-Path -Parent $candidate
                    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
                        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
                    }
                    $stream = [System.IO.File]::Create($candidate)
                    try { $request.InputStream.CopyTo($stream) }
                    finally { $stream.Dispose() }
                    $size = (Get-Item -LiteralPath $candidate).Length
                    Write-Host "UPLOADED: $size bytes" -ForegroundColor Magenta
                    $response.StatusCode = 200
                    $response.Close()
                }
                { $_ -in @('GET', 'HEAD') } {
                    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                        Write-Host 'NOT FOUND' -ForegroundColor Red
                        $response.StatusCode = 404
                        $response.Close()
                        continue
                    }
                    $bytes = [System.IO.File]::ReadAllBytes($candidate)
                    $response.ContentLength64 = $bytes.Length
                    $response.ContentType = switch -Regex ([System.IO.Path]::GetExtension($candidate)) {
                        '^\.cfg$' { 'application/xml'; break }
                        '^\.xml$' { 'application/xml'; break }
                        '^\.log$' { 'text/plain'; break }
                        default { 'application/octet-stream' }
                    }
                    Write-Host 'FOUND' -ForegroundColor Green
                    Write-Host "SIZE: $($bytes.Length) bytes" -ForegroundColor Green
                    if ($method -eq 'GET') {
                        $response.OutputStream.Write($bytes, 0, $bytes.Length)
                    }
                    $response.Close()
                }
                default {
                    Write-Host "METHOD NOT ALLOWED: $method" -ForegroundColor Red
                    $response.StatusCode = 405
                    $response.Close()
                }
            }
        }
        catch [System.Net.HttpListenerException] {
            if ($listener.IsListening) {
                Write-Host "HTTP ERROR: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
            if ($null -ne $context) {
                try { $context.Response.StatusCode = 500; $context.Response.Close() } catch {}
            }
        }
    }
}
finally {
    if ($listener.IsListening) { $listener.Stop() }
    $listener.Close()
    Write-Host 'Listener stopped.' -ForegroundColor Green
}
