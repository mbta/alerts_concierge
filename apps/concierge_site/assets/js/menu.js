export default () => {
  // find toggle control in page
  const toggle = document.querySelector("a[data-menu-toggle='up']");
  if (!toggle) {
    return;
  }

  // add click handler
  toggle.addEventListener("click", e => {
    // determine state of toggle
    const value =
      e.target.getAttribute("data-menu-toggle") === "up" ? "down" : "up";

    // change the menu toggle
    e.target.setAttribute("data-menu-toggle", value);

    // toggle menu visibility
    const menuEl = document.querySelector("header[data-menu='items']");
    if (value === "up") {
      menuEl.classList.add("d-none");
    } else {
      menuEl.classList.remove("d-none");
    }
  });
};
