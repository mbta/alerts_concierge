export const insertAfterElByQuery = (selector, el) => {
  const referenceNode = document.querySelector(selector);
  if (!referenceNode) {
    return;
  }
  referenceNode.parentNode.insertBefore(el, referenceNode.nextSibling);
};

export const removeElByQuery = selector => {
  const el = document.querySelector(selector);
  if (!el) {
    return;
  }
  el.parentNode.removeChild(el);
};
