export default () => {
  const touchSupport =
    "ontouchstart" in window ||
    navigator.maxTouchPoints > 0 ||
    navigator.msMaxTouchPoints > 0;
  if (!touchSupport) {
    document.body.className += " no-touch";
  }
};
