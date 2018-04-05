const defaultButtonClass = "btn btn-outline-primary btn-block";

function clearButtonSelection(toggleButtons) {
  toggleButtons.forEach((buttonEl) => {
    buttonEl.className = defaultButtonClass;
  });
}

function handleToggleClick(e, buttonEl, nextButtonEl, messageEl, toggleButtons) {
  e.preventDefault();
  clearButtonSelection(toggleButtons);
  buttonEl.className = `${defaultButtonClass} btn active`;
  nextButtonEl.dataset.href = buttonEl.getAttribute("href");
  nextButtonEl.removeAttribute("disabled");
  messageEl.innerHTML = buttonEl.dataset.message;
}

function handleNextClick(e, nextButtonEl) {
  e.preventDefault();
  window.location = nextButtonEl.dataset.href;
}

export default () => {
  const messageEl = document.querySelector("div[data-type='trip-type-message']");
  const nextButtonEl = document.querySelector("button[data-type='advance-trip-type']");
  nextButtonEl.addEventListener("click", (e) => handleNextClick(e, nextButtonEl));

  const toggleButtons = [... document.querySelectorAll("a[data-type='toggle-trip-type']")];
  toggleButtons.forEach((buttonEl) => {
    buttonEl.addEventListener("click", (e) => handleToggleClick(e, buttonEl, nextButtonEl, messageEl, toggleButtons));
  });
};
