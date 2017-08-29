export function simulateKeyUp(target) {
  const event = document.createEvent("HTMLEvents");
  event.initEvent("keyup", true, true);
  target.dispatchEvent(event);
}
