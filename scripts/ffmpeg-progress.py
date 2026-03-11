#!/usr/bin/env python3
from ffmpeg_progress_yield import FfmpegProgress
import sys, os

url    = sys.argv[1]
output = sys.argv[2]
name   = sys.argv[3]

PROGRESS_LOG = "/tmp/ffmpeg_progress/jobs.log"
os.makedirs("/tmp/ffmpeg_progress", exist_ok=True)

cmd = ["ffmpeg", "-i", url, "-c", "copy", "-bsf:a", "aac_adtstoasc", output]

had_progress = False

try:
    with FfmpegProgress(cmd) as ff:
        for progress in ff.run_command_with_progress():
            had_progress = True
            with open(PROGRESS_LOG, "a") as f:
                f.write(f"{name}|{progress:.1f}\n")

        if ff.stderr:
            log_file = os.environ.get("LOG_FILE", "/var/log/stream-downloads.log")
            with open(log_file, "a") as f:
                f.write(ff.stderr + "\n")

        if ff.process and ff.process.returncode != 0:
            with open(PROGRESS_LOG, "a") as f:
                f.write(f"{name}|error\n")
            sys.exit(1)

    if not had_progress:
        with open(PROGRESS_LOG, "a") as f:
            f.write(f"{name}|error\n")
        sys.exit(1)

    with open(PROGRESS_LOG, "a") as f:
        f.write(f"{name}|done\n")

except Exception as e:
    log_file = os.environ.get("LOG_FILE", "/var/log/stream-downloads.log")
    with open(log_file, "a") as f:
        f.write(f"{name}: EXCEPTION: {e}\n")
    with open(PROGRESS_LOG, "a") as f:
        f.write(f"{name}|error\n")
    sys.exit(1)
