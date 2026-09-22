<#
================================================================================
  test-resistencia.ps1 - Prueba de resistencia local (organizada)
  yNeoo - 2026
  Uso:   & .\test-resistencia.ps1                 (demo nginx 8090, por defecto)
         & .\test-resistencia.ps1 -UsarDocker     (staging PHP+MariaDB, puerto 8080)
         & .\test-resistencia.ps1 -SoloDiagnostico
         & .\test-resistencia.ps1 -PararAlFinal
  Salida: <staging>\resultados\informe_YYYYMMDD_HHmmss.md
  Docs:  hardening-guides/dos/README_dos.md
  Nota:  ASCII-only de proposito (compatible PowerShell 5.1 sin BOM)
================================================================================
#>
[CmdletBinding()]
param(
    [string]$HostTarget   = "127.0.0.1",
    [int]$Puerto          = 8090,
    [string]$StagingDir   = "C:\Users\zorro\Downloads\staging",
    [int]$RpsBase         = 10,
    [int]$RpsFlood        = 1000,
    [int]$DurBase         = 8,
    [int]$DurFlood        = 8,
    [int]$SlowSockets     = 100,
    [int]$SlowSegundos    = 15,
    [switch]$UsarDocker,       # staging completo (PHP+MariaDB) - requiere engine Linux
    [switch]$PararAlFinal,     # para nginx al terminar
    [switch]$SoloDiagnostico   # solo comprueba herramientas y objetivo
)

$ErrorActionPreference = "Stop"
# decode de salida nativa como UTF-8 (evita mojibake tipo μs en informes)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$target = "http://${HostTarget}:${Puerto}/"
$outDir = Join-Path $StagingDir "resultados"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$stamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$reporte = Join-Path $outDir "informe_$stamp.md"

# ---------------------------------------------------------------- utilidades
function Banner([string]$Titulo, [string]$Color = "Cyan") {
    Write-Host ""
    Write-Host ("=" * 64) -ForegroundColor $Color
    Write-Host ("  " + $Titulo) -ForegroundColor $Color
    Write-Host ("=" * 64) -ForegroundColor $Color
}
function Anotar([string]$Texto) { Add-Content -Path $reporte -Value $Texto -Encoding UTF8 }

function Test-Herramienta([string]$Nombre) {
    return (Get-Command $Nombre -ErrorAction SilentlyContinue) -ne $null
}

function Get-Salud {
    try {
        $code = & curl.exe -s -o NUL -w "%{http_code}" --max-time 8 "$target" 2>$null
        return "$code"
    } catch { return "000" }
}

function Get-ResumenVegeta([string]$Archivo) {
    $txt = (& vegeta report $Archivo 2>&1 | Out-String)
    $lineas = $txt -split "`r?`n"
    $filas = $lineas | Where-Object { $_ -match '^(Requests|Latencies|Success|Status Codes)' }
    return ($filas -join "`n")
}

function Do-Vegeta([string]$Nombre, [int]$Rps, [int]$Dur, [string]$Archivo) {
    Banner "ATAQUE: $Nombre ($Rps rps durante ${Dur}s) -> $target"
    $targetsFile = Join-Path $outDir "targets_$stamp.txt"
    [System.IO.File]::WriteAllText($targetsFile, "GET $target`n", [System.Text.UTF8Encoding]::new($false))
    $targetsArg = "-targets=" + $targetsFile
    $durArg     = "-duration=" + $Dur + "s"
    $rateArg    = "-rate=" + $Rps
    $workersArg = "-workers=100"
    $outArg     = "-output=" + $Archivo
    & vegeta attack $targetsArg $durArg $rateArg $workersArg $outArg 2>&1 | Out-Null
    $resumen = Get-ResumenVegeta $Archivo
    Write-Host $resumen
    Anotar ""
    Anotar "## $Nombre"
    Anotar '```'
    Anotar $resumen
    Anotar '```'
}

# ------------------------------------------------- private: arranque objetivo
function Start-NginxDemo {
    $conf = Join-Path $StagingDir "nginx-test\conf\nginx.conf"
    if (-not (Test-Path $conf)) {
        throw "No existe $conf - configura el demo nginx (ver hardening-guides/dos, seccion 6)."
    }
    if (-not (Get-Process nginx -ErrorAction SilentlyContinue)) {
        Write-Host "  -> Arrancando nginx demo (port $Puerto, blindaje activo)..."
        New-Item -ItemType Directory -Force -Path (Join-Path $StagingDir "nginx-test\logs"),(Join-Path $StagingDir "nginx-test\temp") | Out-Null
        Start-Process nginx -ArgumentList "-p", ("$StagingDir\nginx-test\") -WindowStyle Hidden
        Start-Sleep -Seconds 3
    } else {
        Write-Host "  -> nginx ya estaba corriendo (reutilizado)."
    }
}

function Start-Objetivo {
    if ($UsarDocker) {
        try {
            docker info *> $null
            Write-Host "  -> Docker OK. Levantando staging completo (nginx+php+mariadb)..."
            Push-Location $StagingDir
            & docker compose up -d 2>&1 | Out-Null
            Pop-Location
            $script:Puerto = 8080
        } catch {
            Write-Host "  -> Docker engine NO disponible (falta WSL2?). Uso el demo nginx nativo..." -ForegroundColor Yellow
            Start-NginxDemo
        }
    } else {
        Start-NginxDemo
    }
}

# ------------------------------------------------------------ diagnostico
Anotar "# Informe de resistencia - $stamp"
Banner "DIAGNOSTICO" "Magenta"
$herramientas = @("vegeta","k6","slowloris","nginx","curl")
foreach ($h in $herramientas) {
    $ok = Test-Herramienta $h
    Write-Host ("  {0,-10} {1}" -f $h, $(if ($ok) { "[OK]" } else { "[FALTA]" })) -ForegroundColor $(if ($ok) { "Green" } else { "Yellow" })
    Anotar "- $h -> $(if ($ok) { 'OK' } else { 'FALTA' })"
}
if (-not (Test-Herramienta "vegeta")) { Write-Host "  Falta vegeta: scoop install vegeta" -ForegroundColor Yellow }
if (-not (Test-Herramienta "slowloris")) { Write-Host "  Falta slowloris: pip install slowloris" -ForegroundColor Yellow }

if ($SoloDiagnostico) {
    Write-Host ""
    Write-Host ("  Salud actual de $target : HTTP " + (Get-Salud)) -ForegroundColor Green
    Write-Host ("  Informe: $reporte")
    exit 0
}

Banner "ARRANCANDO OBJETIVO"
Start-Objetivo
$saludAntes = Get-Salud
Write-Host "  Salud inicial : HTTP $saludAntes -> $target" -ForegroundColor $(if ($saludAntes -eq "200") { "Green" } else { "Yellow" })
Anotar ""
Anotar "- Objetivo: $target"
Anotar "- Salud inicial: HTTP $saludAntes"

# ------------------------------------------------- linea base
Do-Vegeta "LINEA BASE" $RpsBase $DurBase (Join-Path $outDir "base_$stamp.bin")

# ------------------------------------------------- flood
Do-Vegeta "FLOOD ($RpsFlood rps)" $RpsFlood $DurFlood (Join-Path $outDir "flood_$stamp.bin")

# ------------------------------------------------- slowloris
if (Test-Herramienta "slowloris") {
    Banner "ATAQUE: SLOWLORIS ($SlowSockets sockets, ${SlowSegundos}s)" "Red"
    Anotar ""
    Anotar "## Slowloris (${SlowSockets} sockets, ${SlowSegundos}s)"
    $logSl = Join-Path $outDir "slowloris_$stamp.out.log"
    $errSl = Join-Path $outDir "slowloris_$stamp.err.log"
    $p = Start-Process slowloris -ArgumentList @($HostTarget, "-p", $Puerto, "-s", $SlowSockets, "-ua") -WindowStyle Hidden -RedirectStandardOutput $logSl -RedirectStandardError $errSl -PassThru
    Write-Host "  -> slowloris lanzado (PID $($p.Id)) - $SlowSockets sockets durante $SlowSegundos s..."
    Start-Sleep -Seconds $SlowSegundos
    Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
    Stop-Process -Name slowloris -Force -ErrorAction SilentlyContinue
    $slowOk = Test-Path $logSl
    Anotar "- Log slowloris: $logSl $(if ($slowOk) { '(generado)' } else { '(sin output)' })"
} else {
    Write-Host "  -> slowloris no instalado - se omite (pip install slowloris)." -ForegroundColor Yellow
}

# ------------------------------------------------- salud post-ataque
Start-Sleep -Seconds 2
$saludPost = Get-Salud
Banner "SALUD POST-ATAQUE"
Write-Host "  Salud final : HTTP $saludPost -> $target" -ForegroundColor $(if ($saludPost -eq "200") { "Green" } else { "Red" })
Anotar ""
Anotar "## Salud post-ataque"
Anotar "- HTTP $saludPost -> $target"

# opcional: cola del log de nginx (prueba del limit_req)
$errLog = Join-Path $StagingDir "nginx-test\logs\error.log"
if (Test-Path $errLog) {
    $rechazos = (Get-Content $errLog -ErrorAction SilentlyContinue | Select-String "limiting requests" | Measure-Object).Count
    Write-Host "  Rechazos de limit_req en log de nginx: $rechazos (prueba del blindaje)" -ForegroundColor Gray
    Anotar "- Rechazos limit_req registrados: $rechazos"
}

# ------------------------------------------------- resumen
Banner "RESUMEN FINAL" "Green"
Write-Host "  Objetivo     : $target"
Write-Host "  Salud inicial: HTTP $saludAntes   |   Salud final: HTTP $saludPost"
Write-Host "  Informe completo: $reporte"
if ($PararAlFinal) {
    Write-Host "  Parando nginx..."
    nginx -p "$StagingDir\nginx-test\" -s stop 2>$null
    Write-Host "  (nginx detenido)"
} else {
    Write-Host "  nginx sigue arriba. Para pararlo: nginx -p `"$StagingDir\nginx-test\`" -s stop"
}