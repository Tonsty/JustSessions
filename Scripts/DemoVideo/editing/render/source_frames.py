"""Streams a take's frames, resampled to 60 fps, and hands out the frame for any later source time."""
import subprocess

from PIL import Image

from paths import TAKES

SOURCE_WIDTH, SOURCE_HEIGHT = 3200, 1800
FPS = 60


class SourceFrames:
    def __init__(self, take, start, end):
        self.start = start
        self.frame_bytes = SOURCE_WIDTH * SOURCE_HEIGHT * 3
        self.process = subprocess.Popen(
            ["ffmpeg", "-v", "error", "-hwaccel", "videotoolbox", "-ss", f"{start:.3f}", "-t", f"{end - start + 0.2:.3f}",
             "-i", str(TAKES / f"{take}.mov"),
             "-vf", f"fps={FPS},scale=in_color_matrix=bt709:in_range=tv:out_range=pc",
             "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
            # Closing early breaks the pipe on purpose, so its complaints are muted; frame_at checks for real output.
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, bufsize=self.frame_bytes)
        self.index, self.current = -1, None

    def frame_at(self, source_time):
        """Times must not go backwards; a time past the end repeats the last frame."""
        wanted = max(0, round((source_time - self.start) * FPS))
        while self.index < wanted:
            data = self.process.stdout.read(self.frame_bytes)
            if len(data) < self.frame_bytes:
                break
            self.current = Image.frombuffer("RGB", (SOURCE_WIDTH, SOURCE_HEIGHT), data, "raw", "RGB", 0, 1)
            self.index += 1
        if self.current is None:
            raise RuntimeError(f"no frames decoded from {self.start:.2f}s")
        return self.current

    def close(self):
        self.process.stdout.close()
        self.process.kill()
        self.process.wait()
