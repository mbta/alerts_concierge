import serialize from "form-serialize";
import { makeErrorMessageEl, makeAlert } from "./user-messages";
import { insertAfterElByQuery, removeElByQuery } from "./dom-utils";
import xhr from "xhr";

export default () => {
  const feedbackFormEl = document.getElementById("feedback-form");
  if (!feedbackFormEl) {
    return;
  }
  feedbackFormEl.addEventListener(
    "submit",
    handlefeedbackFormSubmit(feedbackFormEl),
    false
  );
};

const handlefeedbackFormSubmit = feedbackFormEl => e => {
  e.preventDefault();
  removeElByQuery("#feedback-alert");
  const data = serialize(feedbackFormEl, { hash: true });
  const formValid = validateForm(data);
  if (formValid === false) {
    return;
  }
  xhr(
    {
      method: "post",
      body: JSON.stringify(data),
      uri: feedbackFormEl.getAttribute("data-uri"),
      headers: {
        "Content-Type": "application/json",
        "x-csrf-token": data.token
      }
    },
    (err, resp, body) => {
      let alertEl;
      if (resp.statusCode == 200) {
        alertEl = makeAlert(
          "feedback-alert",
          "alert-success",
          "Thanks for your feedback!"
        );
        feedbackFormEl.reset();
      } else {
        alertEl = makeAlert(
          "feedback-alert",
          "alert-danger",
          "Oops, something went wrong. Please try again later."
        );
      }
      insertAfterElByQuery(".heading__title", alertEl);
      document.getElementById("feedback-alert").focus();
    }
  );
};

const validateForm = data => {
  let formValid = true;
  ["#feedback-why-error", "#feedback-what-error"].forEach(selector =>
    removeElByQuery(selector)
  );
  if (!data.why) {
    formValid = false;
    insertAfterElByQuery(
      "#feedback-why",
      makeErrorMessageEl("feedback-why-error", "This field is required.")
    );
  }
  if (!data.what) {
    formValid = false;
    makeErrorMessageEl("feedback-what", "This field is required.");
    insertAfterElByQuery(
      "#feedback-what",
      makeErrorMessageEl("feedback-what-error", "This field is required.")
    );
  }
  return formValid;
};
