<#
  화면 녹화 + 마이크 녹음 스크립트

  사용법:
    .\record.ps1                 # 녹화 시작, 콘솔에서 q 를 누르면 종료
    .\record.ps1 -Seconds 30     # 30초만 녹화하고 자동 종료
    .\record.ps1 -Fps 60 -Crf 20 # 60fps / 더 높은 화질
    .\record.ps1 -ListDevices    # 오디오 입력 장치 목록 확인
#>
param(
    [int]    $Seconds = 0,                 # 0 이면 q 를 누를 때까지 계속 녹화
    [int]    $Fps     = 30,
    [int]    $Crf     = 23,                # 낮을수록 고화질/큰 용량 (18~28 권장)
    [string] $Output  = "",
    [string] $Mic     = "@device_cm_{33D9A762-90C8-11D0-BD43-00A0C911CE86}\wave_{6E83BF17-26AD-4447-AC73-064C42F4486A}",  # 마이크(Realtek(R) Audio)
    [switch] $NoAudio,
    [switch] $ListDevices
)

$ErrorActionPreference = "Stop"
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

# ffmpeg 위치 찾기 (PATH → winget 설치 경로 순)
$ffmpeg = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $ffmpeg) {
    $ffmpeg = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter ffmpeg.exe -ErrorAction SilentlyContinue |
              Select-Object -First 1 -ExpandProperty FullName
}
if (-not $ffmpeg) { throw "ffmpeg 를 찾을 수 없습니다. winget install Gyan.FFmpeg 로 설치하세요." }

if ($ListDevices) {
    & $ffmpeg -hide_banner -list_devices true -f dshow -i dummy
    exit 0
}

if (-not $Output) {
    $Output = Join-Path $PSScriptRoot ("녹화_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".mp4")
}

$args = @(
    "-hide_banner", "-y",
    # 화면 (전체 데스크톱, 마우스 커서 포함)
    "-f", "gdigrab", "-framerate", "$Fps", "-draw_mouse", "1", "-i", "desktop"
)
if (-not $NoAudio) {
    $args += @("-f", "dshow", "-audio_buffer_size", "50", "-i", "audio=$Mic")
}
$args += @(
    "-vf", "scale=trunc(iw/2)*2:trunc(ih/2)*2",   # libx264 는 짝수 해상도 필요
    "-c:v", "libx264", "-preset", "veryfast", "-crf", "$Crf", "-pix_fmt", "yuv420p",
    "-movflags", "+faststart"
)
if (-not $NoAudio) { $args += @("-c:a", "aac", "-b:a", "192k", "-ac", "2") }
if ($Seconds -gt 0) { $args += @("-t", "$Seconds") }
$args += $Output

Write-Host "녹화 시작 -> $Output"
if ($Seconds -gt 0) { Write-Host "$Seconds 초 후 자동 종료됩니다." }
else { Write-Host "중지하려면 이 창에서 q 를 누르세요." }

& $ffmpeg @args

if (Test-Path $Output) {
    $mb = [math]::Round((Get-Item $Output).Length / 1MB, 2)
    Write-Host "`n완료: $Output ($mb MB)"
}
