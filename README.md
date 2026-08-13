# 화면 녹화 + 마이크 녹음

Windows에서 전체 화면과 마이크를 동시에 녹화해 하나의 MP4 파일로 저장하는 ffmpeg 기반 스크립트입니다.

- 영상: 전체 데스크톱 1920×1080, 30fps, 마우스 커서 포함, H.264(libx264)
- 음성: 시스템 마이크 입력, AAC 192kbps 스테레오
- 출력: `녹화_20260813_150700.mp4` 형식으로 이 폴더에 저장

## 빠른 시작

폴더의 빈 곳에서 우클릭 → **터미널에서 열기** 후 아래 명령을 붙여넣고 엔터:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File record.ps1
```

녹화를 멈추려면 그 창에서 **`q`** 를 누릅니다. (창을 그냥 닫으면 파일이 손상될 수 있습니다.)

`녹화시작.bat` 을 더블클릭해도 동일하게 동작합니다.

## 설치 (최초 1회)

ffmpeg가 필요합니다. 이미 설치되어 있다면 건너뛰세요.

```powershell
winget install --id Gyan.FFmpeg -e --scope user
```

스크립트는 `PATH` → winget 설치 경로 순으로 ffmpeg를 자동으로 찾습니다.

## 사용법

| 목적 | 명령 |
| --- | --- |
| 기본 녹화 (`q` 로 중지) | `.\record.ps1` |
| 30초만 녹화 후 자동 종료 | `.\record.ps1 -Seconds 30` |
| 60fps 고화질 | `.\record.ps1 -Fps 60 -Crf 18` |
| 화면만 (소리 없음) | `.\record.ps1 -NoAudio` |
| 저장 위치 직접 지정 | `.\record.ps1 -Output D:\영상\회의.mp4` |
| 오디오 장치 목록 확인 | `.\record.ps1 -ListDevices` |

### 옵션

| 옵션 | 기본값 | 설명 |
| --- | --- | --- |
| `-Seconds` | `0` | 녹화 길이(초). `0`이면 `q` 를 누를 때까지 계속 |
| `-Fps` | `30` | 초당 프레임 수 |
| `-Crf` | `23` | 화질. 낮을수록 고화질·큰 용량 (18~28 권장) |
| `-Output` | 자동 | 저장 경로. 미지정 시 `녹화_날짜_시간.mp4` |
| `-Mic` | Realtek 마이크 | 사용할 오디오 입력 장치 |
| `-NoAudio` | 꺼짐 | 마이크 없이 화면만 녹화 |
| `-ListDevices` | 꺼짐 | 장치 목록만 출력하고 종료 |

### 마이크 바꾸기

`-ListDevices` 로 목록을 확인한 뒤, 원하는 장치의 **Alternative name**(`@device_cm_{...}` 형태)을 그대로 넘기는 것이 가장 안전합니다. 장치 이름에 한글이 있어도 문제가 없습니다.

```powershell
.\record.ps1 -Mic "@device_cm_{33D9A762-90C8-11D0-BD43-00A0C911CE86}\wave_{...}"
```

기본값은 `마이크(Realtek(R) Audio)` 입니다. `Steam Streaming Microphone` 은 가상 장치라 실제 음성이 녹음되지 않습니다.

## 문제 해결

**녹음된 소리가 없거나 너무 작음**
Windows 설정 → 시스템 → 소리 → 입력에서 Realtek 마이크가 선택돼 있고 음소거가 아닌지, 입력 볼륨이 0이 아닌지 확인하세요. 녹화 파일의 실제 음량은 이렇게 확인할 수 있습니다.

```powershell
ffmpeg -i 녹화_20260813_150700.mp4 -af volumedetect -f null -
```

`mean_volume` 이 -70dB 이하면 사실상 무음입니다.

**콘솔에 한글이 `?뱁솕` 처럼 깨지거나 `Error opening output ... Invalid argument` 발생**
`record.ps1` 이 BOM 없는 UTF-8로 저장된 경우입니다. Windows PowerShell 5.1은 BOM이 없으면 스크립트를 ANSI(949)로 읽기 때문에 스크립트 안의 한글 문자열이 깨지고, 그 깨진 이름으로 파일을 만들려다 실패합니다. 편집기에서 **UTF-8 with BOM** 으로 다시 저장하거나 아래를 실행하세요.

```powershell
$p = "record.ps1"; $c = Get-Content -Raw -Encoding UTF8 $p; [IO.File]::WriteAllText($p, $c, (New-Object System.Text.UTF8Encoding($true)))
```

**`이 시스템에서 스크립트를 실행할 수 없으므로` 오류**
실행 정책 때문입니다. 위 사용법처럼 `-ExecutionPolicy Bypass` 를 붙여 실행하세요.

**`ffmpeg 를 찾을 수 없습니다`**
설치 직후라면 터미널을 새로 열어야 `PATH` 가 반영됩니다.

**녹화가 버벅이거나 파일이 너무 큼**
`-Fps 15` 로 낮추거나 `-Crf 28` 로 압축률을 높이세요. 반대로 화질이 아쉬우면 `-Crf 18`.

## 참고

- 화면은 전체 데스크톱만 녹화합니다. 특정 창이나 영역만 녹화하려면 ffmpeg의 `gdigrab` 옵션(`-i title=창제목`, `-offset_x/-offset_y/-video_size`)을 추가해야 합니다.
- 스피커로 나오는 소리(시스템 사운드)는 녹음되지 않습니다. 마이크 입력만 포함됩니다.
- 결과물이 `.mp4` 로 폴더에 계속 쌓이므로 주기적으로 정리하세요.
