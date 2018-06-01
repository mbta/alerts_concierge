export default function(pubsub, $) {
  $ = $ || window.jQuery;

  $("label[role='radio']").on("keypress", triggerClick());
  $("label[role='radio']").on("click", toggleRadio(pubsub, $));
  pubsub.subscribe("radio-change", toggleEvents($));
}

function toggleRadio(pubsub, $) {
  return e => {
    const $targetLabelEl = $(e.target);
    const selectedId = $targetLabelEl.data("id");
    const $parentEl = $targetLabelEl.parents("div[role='radiogroup']");

    // update selection indicators and values, publish to subscribers
    $parentEl.find("label").each(function(index, value) {
      const $labelEl = $(value);
      if ($labelEl.data("id") == selectedId) {
        $labelEl.attr("aria-checked", "true");
        $labelEl.addClass("active");
        $labelEl.find("input").attr("checked", "checked");
        pubsub.publishSync("radio-change", {
          changedEl: $labelEl
        });
      } else {
        $labelEl.attr("aria-checked", "false");
        $labelEl.removeClass("active");
        $labelEl.find("input").removeAttr("checked");
      }
    });
  };
}

function triggerClick() {
  return function(e) {
    const code = e.keyCode || e.which;
    if (code == 13 || code == 32) {
      e.preventDefault();
      e.stopPropagation();
      $(e.target).click();
    }
  };
}

function toggleEvents($) {
  return ({ changedEl: $labelEl }) => {
    const $inputEl = $labelEl.find("input");
    const inputName = $inputEl.attr("name");
    const inputValue = $inputEl.attr("value");

    switch (inputName) {
      case "user[sms_toggle]":
        const $phoneContainerEl = $("div[data-phone='input']");
        if (inputValue == "true") {
          $phoneContainerEl.removeClass("d-none");
          $phoneContainerEl.find("input").attr("required", "required");
          setTimeout(() => {
            $phoneContainerEl.find("input").focus();
          }, 250);
        } else {
          $phoneContainerEl.addClass("d-none");
          $phoneContainerEl.find("input").removeAttr("required");
        }
        break;
    }
  };
}
