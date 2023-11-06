import $ from "jquery";
import { toggleVisibleSelector } from "./select-route-choices";
import { toggleBusDirection } from "./bus-direction-toggle";

export default function (pubsub) {
  $("label[role='radio']").on("keypress", triggerClick());
  $("label[role='radio']").on("click", toggleRadio(pubsub, $));
  $("label[role='checkbox']").on("keypress", triggerClick());
  $("label[role='checkbox']").on("click", toggleCheckbox(pubsub, $));
  pubsub.subscribe("radio-change", toggleEvents($));
}

function toggleCheckbox(pubsub, $) {
  return e => {
    e.preventDefault();
    const $targetLabelEl = $(e.target);
    const isChecked = $targetLabelEl
      .find("input[type='checkbox']")
      .attr("checked");
    setTimeout(() => {
      pubsub.publishSync("checkbox-change", {
        changedEl: $targetLabelEl,
        isChecked: !isChecked
      });
      if (isChecked == "checked") {
        $targetLabelEl.find("input[type='checkbox']").removeAttr("checked");
        $targetLabelEl.find("input[type='hidden']").attr("value", "false");
        $targetLabelEl.attr("aria-checked", "false");
        $targetLabelEl.removeClass("active");
      } else {
        $targetLabelEl
          .find("input[type='checkbox']")
          .attr("checked", "checked");
        $targetLabelEl.find("input[type='hidden']").attr("value", "true");
        $targetLabelEl.attr("aria-checked", "true");
        $targetLabelEl.addClass("active");
      }
    }, 10);
  };
}

function toggleRadio(pubsub, $) {
  return e => {
    const $targetLabelEl = $(e.target);
    const selectedId = $targetLabelEl.data("id");
    if (!selectedId) {
      return;
    }
    const $parentEl = $targetLabelEl.parents("div[role='radiogroup']");

    // update selection indicators and values, publish to subscribers
    $parentEl.find("label").each(function (index, value) {
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
  return function (e) {
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
        const $communicationModelEl = $("#user_communication_mode");
        if (inputValue == "true" && !$labelEl.hasClass("disabled")) {
          $phoneContainerEl.removeClass("d-none");
          $communicationModelEl.val("sms");
          setTimeout(() => {
            $phoneContainerEl.find("input").focus();
          }, 250);
        } else {
          $communicationModelEl.val("email");
          $phoneContainerEl.addClass("d-none");
        }
        break;

      case "trip[new_leg]":
        const $connectionContainerEl = $("div[data-type='connection']");
        if (inputValue == "true") {
          $connectionContainerEl.removeClass("d-none");
          setTimeout(() => {
            $connectionContainerEl.find("select").focus();
          }, 250);
        } else {
          $connectionContainerEl.addClass("d-none");
        }
        break;

      case "mode_toggle":
        toggleVisibleSelector(inputValue);
        break;

      case "trip[direction]":
        toggleBusDirection(inputValue);
        break;
    }
  };
}
