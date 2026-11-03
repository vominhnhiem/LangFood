param (
    [int]$Port = 8080,
    [string]$Path = "$PSScriptRoot\build\web"
)

$listener = New-Object System.Net.HttpListener
$prefix = "http://localhost:$Port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Server started at $prefix serving $Path"

$mimeMap = @{
    ".html" = "text/html; charset=utf-8";
    ".js"   = "application/javascript";
    ".mjs"  = "application/javascript";
    ".json" = "application/json";
    ".css"  = "text/css";
    ".png"  = "image/png";
    ".jpg"  = "image/jpeg";
    ".jpeg" = "image/jpeg";
    ".svg"  = "image/svg+xml";
    ".wasm" = "application/wasm";
    ".ttf"  = "font/ttf";
    ".otf"  = "font/otf";
    ".woff" = "font/woff";
    ".woff2"= "font/woff2";
    ".ico"  = "image/x-icon"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        $urlPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($urlPath)) {
            $urlPath = "index.html"
        }

        $filePath = Join-Path $Path $urlPath
        if (-not (Test-Path $filePath -PathType Leaf)) {
            $filePath = Join-Path $Path "index.html"
        }

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = "application/octet-stream"
            if ($mimeMap.ContainsKey($ext)) {
                $contentType = $mimeMap[$ext]
            }

            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    }
} finally {
    $listener.Stop()
}
