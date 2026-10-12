import { connectDemoVideo } from "./demo-video-player.js";

const demo = document.querySelector("[data-demo-video]");
if (demo) {
  connectDemoVideo({
    video: demo.querySelector("[data-demo-video-player]"),
    playButton: demo.querySelector("[data-demo-video-play]"),
    chapterList: demo.querySelector("[data-demo-chapters]"),
    chapterButtons: [...demo.querySelectorAll("[data-demo-chapter]")],
  });
}
