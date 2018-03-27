export default function($) {
  $ = $ || window.jQuery;

  $("div[data-selector='date']").each(function (i, div) {
    new DaySelector($(div));
  });
}

function DaySelector($div) {
  enable($div);

  this.inputs = {
    monday: getInput($div, "monday"),
    tuesday: getInput($div, "tuesday"),
    wednesday: getInput($div, "wednesday"),
    thursday: getInput($div, "thursday"),
    friday: getInput($div, "friday"),
    saturday: getInput($div, "saturday"),
    sunday: getInput($div, "sunday"),
    weekdays: getInput($div, "weekdays"),
    weekend: getInput($div, "weekend")
  };
  this.labels = {};
  this.state = {};

  this.labelsFromInputs();
  this.stateFromHtml();
  this.addListeners();
}

DaySelector.prototype.labelsFromInputs = function() {
  for (var day in this.inputs) {
    this.labels[day] = this.inputs[day].parent("label");
  }
};

DaySelector.prototype.addListeners = function() {
  var that = this;

  for (var day in this.labels) this.labels[day].on("click", renderFn(this, day));

  return this;
};

DaySelector.prototype.stateFromHtml = function() {
  for (var day in this.labels) {
    this.state[day] = isClicked(this.labels[day]);
  }

  return this;
};

DaySelector.prototype.htmlFromState = function() {
  for (var day in this.state) {
    if (this.state[day]) {
      clickLabel(this.labels[day]);
      check(this.inputs[day]);
      addCheckIcon(this.inputs[day]);
    }
    else {
      unclickLabel(this.labels[day]);
      uncheck(this.inputs[day]);
      removeCheckIcon(this.inputs[day]);
    }
  }

  return this;
};

DaySelector.prototype.toggleState = function(day) {
  var state = this.state;

  if (day === "weekdays") {
    if (state.weekdays) {
      state.monday = false;
      state.tuesday = false;
      state.wednesday = false;
      state.thursday = false;
      state.friday = false;
      state.weekdays = false;
    } else {
      state.monday = true;
      state.tuesday = true;
      state.wednesday = true;
      state.thursday = true;
      state.friday = true;
      state.weekdays = true;
    }
  } else if (day === "weekend") {
    if (state.weekend) {
      state.saturday = false;
      state.sunday = false;
      state.weekend = false;
    } else {
      state.saturday = true;
      state.sunday = true;
      state.weekend = true;
    }
  } else {
    if (state[day]) {
      state[day] = false;
    } else {
      state[day] = true;
    }

    if (state.monday && state.tuesday && state.wednesday && state.thursday && state.friday) {
      state.weekdays = true;
    } else {
      state.weekdays = false;
    }

    if (state.saturday && state.sunday) {
      state.weekend = true;
    } else {
      state.weekend = false;
    }
  }

  return this;
};

function enable($div) {
  $div.find(".btn-group-toggle").data("toggle", "buttons");
  $div.find(".invisible-no-js").removeClass("invisible-no-js");
  $div.find("input").addClass("invisible-js");
}

function getInput($div, value) {
  return $div.find(`:input[value='${value}']`);
}

function renderFn(that, day) {
  return function (e) {
    e.preventDefault();
    e.stopPropagation();

    that.toggleState(day);
    that.htmlFromState();
  };
}

function clickLabel($label) {
  if (!isClicked($label)) $label.button("toggle");
}

function unclickLabel($label) {
  if (isClicked($label)) $label.button("toggle");
}

function check($input) {
  $input.prop('checked', true);
}

function uncheck($input) {
  $input.prop('checked', false);
}

function addCheckIcon($input) {
  $input.siblings("i").addClass("fa fa-check");
}

function removeCheckIcon($input) {
  $input.siblings("i").removeClass("fa fa-check");
}

function isClicked($label) {
  return $label.hasClass("active");
}
