# Servidor estático simples (sem Python/Node) para a vitrine Hinove.
param([int]$Port = 8123)

$root = Join-Path $PSScriptRoot "."
$listener = New-Object System.Net.HttpListener
try {
    $listener.Prefixes.Add("http://+:$Port/")
    $listener.Start()
    Write-Host "hinove-showcase servindo em todas as interfaces, porta $Port"
} catch {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()
    Write-Host "hinove-showcase: http://localhost:$Port/ (somente localhost)"
}

$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".svg"  = "image/svg+xml"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".ico"  = "image/x-icon"
}

while ($listener.IsListening) {
    try {
        $ctx = $listener.GetContext()
        $path = $ctx.Request.Url.AbsolutePath
        if ($path -eq "/") { $path = "/index.html" }
        $file = Join-Path $root ($path.TrimStart("/") -replace "/", "\")
        $fullRoot = (Resolve-Path $root).Path
        $ok = (Test-Path $file -PathType Leaf)
        if ($ok) {
            $full = (Resolve-Path $file).Path
            if (-not $full.StartsWith($fullRoot)) { $ok = $false }
        }
        $ctx.Response.Headers.Add("Cache-Control", "no-store, max-age=0")
        if ($ok) {
            $bytes = [System.IO.File]::ReadAllBytes($file)
            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            if ($mime.ContainsKey($ext)) { $ctx.Response.ContentType = $mime[$ext] }
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $ctx.Response.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $ctx.Response.OutputStream.Write($msg, 0, $msg.Length)
        }
        $ctx.Response.OutputStream.Close()
    } catch {
        # segue servindo
    }
}
