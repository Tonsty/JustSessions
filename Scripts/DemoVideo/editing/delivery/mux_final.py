"""Masters the audio mix and joins it with the rendered video into the master, output/JustSessions-demo.mp4.

Mastering is a fixed gain to -16 LUFS integrated (web players and social uploads) and a limiter that holds the
few loudest transients under -2 dBFS, leaving room for inter-sample peaks after AAC encoding.
"""
import json
import subprocess

from paths import BUILD, MASTER

TARGET_LOUDNESS = -16.0
LIMITER = "alimiter=limit=-2dB:attack=1:release=50:level=disabled"


def loudness(path):
    result = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", "loudnorm=print_format=json",
                             "-f", "null", "-"], capture_output=True, text=True, check=True)
    return json.loads(result.stderr[result.stderr.rindex("{"):result.stderr.rindex("}") + 1])


def main():
    measured = loudness(BUILD / "audio.wav")
    gain = TARGET_LOUDNESS - float(measured["input_i"])
    master = f"volume={gain:.2f}dB,{LIMITER}"
    MASTER.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(BUILD / "video.mp4"), "-i", str(BUILD / "audio.wav"),
                    "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-af", master, "-ar", "48000",
                    "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart", str(MASTER)], check=True)
    result = loudness(MASTER)
    print(f"mix {measured['input_i']} LUFS, gain {gain:+.2f} dB; "
          f"output {result['input_i']} LUFS, true peak {result['input_tp']} dBTP")
    print(f"wrote {MASTER}")


if __name__ == "__main__":
    main()
