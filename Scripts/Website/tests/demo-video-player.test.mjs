import test from "node:test";
import assert from "node:assert/strict";
import { chapterIndexAt, chapterProgress, connectDemoVideo } from "../../../website/scripts/demo-video/demo-video-player.js";

const chapters = [{ start: 3, end: 9.5 }, { start: 9.5, end: 15.5 }];

function createElement(extra = {}) {
  const listeners = {};
  const element = {
    hidden: true,
    attributes: {},
    listeners,
    addEventListener(type, listener) { (listeners[type] ??= []).push(listener); },
    dispatch(type) { for (const listener of listeners[type] ?? []) listener(); },
    setAttribute(name, value) { this.attributes[name] = value; },
    removeAttribute(name) { delete this.attributes[name]; },
  };
  // Copies accessors as accessors, so a fake video's currentTime setter keeps recording seeks.
  return Object.defineProperties(element, Object.getOwnPropertyDescriptors(extra));
}

function createVideo() {
  return createElement({
    controls: true,
    paused: true,
    ended: false,
    time: 0,
    events: [],
    play() {
      this.events.push("play");
      // Like a browser, playing after the end starts over.
      if (this.ended) this.time = 0;
      this.paused = false;
      this.ended = false;
      return Promise.resolve();
    },
    set currentTime(time) { this.time = time; this.events.push(`seek ${time}`); },
    get currentTime() { return this.time; },
  });
}

function createDemo() {
  const video = createVideo();
  const playButton = createElement();
  const chapterList = createElement();
  const chapterButtons = chapters.map(({ start, end }) => {
    const fill = { style: {} };
    return createElement({ dataset: { start: String(start), end: String(end) }, fill, querySelector: () => fill });
  });
  connectDemoVideo({ video, playButton, chapterList, chapterButtons, requestFrame: () => {} });
  video.events.length = 0;
  return { video, playButton, chapterList, chapterButtons };
}

test("progress fills each chapter from its start to its end", () => {
  assert.deepEqual(chapterProgress(chapters, 0), [0, 0]);
  assert.deepEqual(chapterProgress(chapters, 6.25), [0.5, 0]);
  assert.deepEqual(chapterProgress(chapters, 52), [1, 1]);
});

test("no chapter is current during the title or the closing card", () => {
  assert.equal(chapterIndexAt(chapters, 1), -1);
  assert.equal(chapterIndexAt(chapters, 9.5), 1);
  assert.equal(chapterIndexAt(chapters, 50), -1);
});

test("with JavaScript the poster shows one play button and the chapters", () => {
  const { video, playButton, chapterList } = createDemo();
  assert.equal(video.controls, false);
  assert.equal(playButton.hidden, false);
  assert.equal(chapterList.hidden, false);
});

test("the play button starts the demo and hands over to the native controls", () => {
  const { video, playButton } = createDemo();
  playButton.dispatch("click");
  assert.deepEqual(video.events, ["play"]);
  assert.equal(video.paused, false);
  assert.equal(video.controls, true);
  assert.equal(playButton.hidden, true);
});

test("a chapter plays from its start, also after the demo has ended", () => {
  const { video, chapterButtons } = createDemo();
  video.ended = true;
  video.currentTime = 52.6;
  video.events.length = 0;
  chapterButtons[1].dispatch("click");
  assert.equal(video.currentTime, 9.5);
  assert.deepEqual(video.events, ["play", "seek 9.5"]);
});

test("the playing chapter is marked and earlier chapters show as watched", () => {
  const { video, chapterButtons } = createDemo();
  video.currentTime = 12.5;
  video.dispatch("timeupdate");
  assert.equal(chapterButtons[0].fill.style.transform, "scaleX(1)");
  assert.equal(chapterButtons[1].fill.style.transform, "scaleX(0.5)");
  assert.equal(chapterButtons[0].attributes["aria-current"], undefined);
  assert.equal(chapterButtons[1].attributes["aria-current"], "true");
});
