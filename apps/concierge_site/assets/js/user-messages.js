export const makeErrorMessageEl = (id, message) => {
  const outerEl = document.createElement("div");
  outerEl.setAttribute("id", id);

  const containerEl = document.createElement("div");
  containerEl.setAttribute("class", "error-block-container");

  const messageEl = document.createElement("span");
  messageEl.setAttribute("class", "error-block");
  messageEl.textContent = message;

  containerEl.appendChild(messageEl);
  outerEl.appendChild(containerEl);

  return outerEl;
};

export const makeAlert = (id, alertType, message) => {
  const el = document.createElement("div");
  el.setAttribute("id", id);
  el.setAttribute("class", `alert ${alertType}`);
  el.setAttribute("tabindex", "0");
  el.textContent = message;
  return el;
};
