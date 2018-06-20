// adds a node to dom that will be spoken by screenreader, clears any previous text
let speakerContainerEl = false;

export const say = text => {
  // find speaker container in page
  speakerContainerEl = speakerContainerEl
    ? speakerContainerEl
    : document.querySelector("[data-type='speaker']");

  // clear existing text from speaker container
  while (speakerContainerEl.firstChild) {
    speakerContainerEl.removeChild(speakerContainerEl.firstChild);
  }

  // add a new span containing text to be spoken
  const speakEl = document.createElement("span");
  speakEl.innerHTML = text;
  speakerContainerEl.appendChild(speakEl);
};
