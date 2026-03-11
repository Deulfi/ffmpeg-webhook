# ffmpeg-webhook

Personal project - I have no idea what I'm doing, and this exists so I don't forget how it works.

When I'm watching something in MPV and want to keep it, I'd rather download it directly to my server where it belongs, instead of downloading to my PC and moving it over. Other download tools exist, but some streams only work well with ffmpeg - and if it plays in MPV, chances are ffmpeg can grab it too (direct streams only - YouTube and the like are another animal entirely).

Since ffmpeg isn't really a download manager and not exactly fast, there's a small web dashboard (via websocketd) that shows whether a download actually started, how far along it is, and if it finished. Don't expect too much from it - it's just there so you're not staring into the void wondering if anything is happening.

Runs on a Debian LXC on Proxmox. Should work on any Debian/Ubuntu.

## How it works

MPV (lua) ──POST──▶ webhook ──▶ download-stream.sh ──▶ ffmpeg-progress.py
│
ffmpeg (-c copy, progress parsed)
│
▼
/tmp/ffmpeg_progress/jobs.log
│
websocketd (tail -f) ──WS──▶ Browser


## Install

```bash
apt install -y git
git clone https://github.com/Deulfi/ffmpeg-webhook /opt/ffmpeg-webhook
cd /opt/ffmpeg-webhook
./install.sh

The installer prompts you to edit .env (set DOWNLOAD_DIR).
MPV client setup

Copy client/ffmpeg_webhook.lua to your MPV scripts folder:

OS	Path
Linux	~/.config/mpv/scripts/ffmpeg_webhook.lua
Windows	%APPDATA%\mpv\scripts\ffmpeg_webhook.lua

Edit WEBHOOK_URL at the top of the file:

lua
local WEBHOOK_URL = "http://<server>:9000/hooks/download-stream"

Keybind — add to input.conf:

ctrl+d script-message-to ffmpeg_webhook download-ffmpeg

uosc button — add to uosc.conf controls:

button:ffmpeg_webhook

Usage

    Play a stream in MPV
    Ctrl+D (or click the uosc download button)
    Confirm/edit the filename
    Watch progress at http://<server>:8080/

Update

Just pull and rerun the installer:

bash
git pull
cd /opt/ffmpeg-webhook
./install.sh

Updates system packages, ffmpeg-progress-yield, websocketd, clears logs, restarts services.
Config

.env:

Var	Default	Purpose
WEBHOOK_PORT	9000	webhook listen port
WEBSOCKET_PORT	8080	dashboard + websocket port
DOWNLOAD_DIR	—	where files land
LOG_FILE	/tmp/ffmpeg_progress/debug.log	ffmpeg stderr / exceptions

Debugging

bash
tail -f /tmp/ffmpeg_progress/debug.log   # ffmpeg errors
tail -f /tmp/ffmpeg_progress/jobs.log    # raw progress stream (name|percent)
journalctl -fu webhook
journalctl -fu websocketd

File overview

/opt/ffmpeg-webhook/
├── .env                          your config (gitignored)
├── .env.example
├── config/
│   ├── webhook.conf              webhook endpoint definition
│   ├── webhook.service           systemd unit (overrides distro unit)
│   └── websocketd.service        systemd unit
├── scripts/
│   ├── download-stream.sh        webhook entrypoint
│   ├── ffmpeg-progress.py        runs ffmpeg, writes progress
│   └── ws-progress.sh            tail -f for websocketd
├── web/index.html                dashboard
├── client/ffmpeg_webhook.lua     MPV script
└── install.sh                    install + update
