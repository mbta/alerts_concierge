import getIcon from "./route-icons";

export default function($) {
  $ = $ || window.jQuery;

  const options = {
    templateResult: formatStop,
    templateSelection: formatStop,
    theme: "bootstrap4",
    placeholder: "Select a stop"
  };

  $("select[data-type='stop']").each(function() {
    $(this).select2(options);
    addSameStopValidationIfTripLegForm($(this));
  });
};

function formatStop(stop) {
  const $el = $(stop.element);
  const className = "float-right";
  const accessible = $el.data("accessible") ? getIcon("accessible")(className) : "";
  const red = $el.data("red") ? getIcon("red")(className) : "";
  const orange = $el.data("orange") ? getIcon("orange")(className) : "";
  const blue = $el.data("blue") ? getIcon("blue")(className) : "";
  const green = $el.data("green") ? getIcon("green")(className) : "";
  const mattapan = $el.data("mattapan") ? getIcon("mattapan")(className) : "";
  const cr = $el.data("cr") ? getIcon("cr")(className) : "";
  const bus = $el.data("bus") ? getIcon("bus")(className) : "";
  const ferry = $el.data("ferry") ? getIcon("ferry")(className) : "";
  return $(`<span>${stop.text}${accessible}${ferry}${cr}${bus}${mattapan}${blue}${green}${orange}${red}</span>`);
};

function addSameStopValidationIfTripLegForm(selectStopComponent) {
  if (isTripLegForm()) {
    selectStopComponent.on("select2:select", disableSubmitButtonIfSameStops);
  }
}

function isTripLegForm() {
  return $("#tripleg-form").length > 0
}

function disableSubmitButtonIfSameStops() {
  const origin = $("#select2-trip_origin-container").attr("title")
  const destination = $("#select2-trip_destination-container").attr("title")
  if (origin == destination) {
    $("button[type='submit']").attr("disabled", "disabled");
  } else {
    $("button[type='submit']").removeAttr("disabled");
  }
}
