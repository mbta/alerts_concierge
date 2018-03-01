import getIcon from "./route-icons";
const NAME_LIMIT = 50;

export default function($) {
  $ = $ || window.jQuery;

  var selectApplied = false;
  const options = {
    templateResult: formatRoute,
    templateSelection: formatRoute,
    theme: "bootstrap4",
    placeholder: "Select a subway, commuter rail, ferry or bus route"
  };

  $("select[data-type='route']").each(function() {
     $(this).select2(options);
  });
};

function formatRoute(route) {
  const icon = $(route.element).data("icon");
  if (!icon) {
    return truncateName(route.text, NAME_LIMIT);
  }
  return $(`<span>${getIcon(icon)("float-left")} ${truncateName(route.text, NAME_LIMIT)}</span>`);
};

function truncateName(name, limit) {
  if (name.length < limit) {
    return name;
  }
  let suffix = "";
  if (name.indexOf(" - Outbound") != -1) {
    suffix = " - Outbound";
    name = name.replace(suffix, "");
  } else if (name.indexOf(" - Inbound") != -1) {
    suffix = " - Inbound";
    name = name.replace(suffix, "");
  }
  return `${name.substring(0, limit).trim()}…${suffix}`;
}
