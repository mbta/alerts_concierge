function simulateKeyUp(target) {
  const event = document.createEvent("HTMLEvents");
  event.initEvent("keyup", true, true);
  target.dispatchEvent(event);
}

function simulateKeyPress(target, keyCode) {
  const event = document.createEvent("HTMLEvents");
  event.initEvent("keydown", true, true);
  event.keyCode = keyCode;
  target.dispatchEvent(event);
  simulateKeyUp(target);
}

export {
  simulateKeyPress,
  simulateKeyUp
}
