// The demo plays with sound only after a visitor asks. Chapters jump within it and fill as it plays.
// Without JavaScript the page keeps the video's native controls and hides the play button and chapters.

/** How much of each chapter has played, from 0 to 1. */
export function chapterProgress(chapters, time) {
  return chapters.map(({ start, end }) => Math.min(1, Math.max(0, (time - start) / (end - start))));
}

/** The chapter playing at `time`, or -1 before the first chapter and after the last. */
export function chapterIndexAt(chapters, time) {
  return chapters.findIndex(({ start, end }) => time >= start && time < end);
}

export function connectDemoVideo({ video, playButton, chapterList, chapterButtons, requestFrame = requestAnimationFrame }) {
  const chapters = chapterButtons.map((button) => ({ start: Number(button.dataset.start), end: Number(button.dataset.end) }));
  const fills = chapterButtons.map((button) => button.querySelector("[data-demo-chapter-fill]"));
  let frameRequested = false;

  function showProgress() {
    const progress = chapterProgress(chapters, video.currentTime);
    const playingIndex = chapterIndexAt(chapters, video.currentTime);
    chapterButtons.forEach((button, index) => {
      fills[index].style.transform = `scaleX(${progress[index]})`;
      if (index === playingIndex) button.setAttribute("aria-current", "true");
      else button.removeAttribute("aria-current");
    });
  }

  function followPlayback() {
    frameRequested = false;
    showProgress();
    if (!video.paused && !video.ended) {
      frameRequested = true;
      requestFrame(followPlayback);
    }
  }

  function play(fromTime) {
    playButton.hidden = true;
    video.controls = true;
    // A browser that still refuses playback leaves the native controls to try again.
    video.play()?.catch(() => {});
    // After the end, play() rewinds to the start, so the chapter's seek has to come after it.
    if (fromTime !== undefined) video.currentTime = fromTime;
  }

  video.controls = false;
  playButton.hidden = false;
  chapterList.hidden = false;
  playButton.addEventListener("click", () => play());
  chapterButtons.forEach((button, index) => button.addEventListener("click", () => play(chapters[index].start)));
  video.addEventListener("play", () => {
    playButton.hidden = true;
    video.controls = true;
    if (!frameRequested) followPlayback();
  });
  for (const type of ["seeked", "timeupdate", "ended"]) video.addEventListener(type, showProgress);
  showProgress();
}
