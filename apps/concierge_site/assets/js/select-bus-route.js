export default function($) {
  $ = $ || window.jQuery;

  let props = {};
  let state = {
    route: undefined,
  };

  if ($(".enter-trip-info").length) {
    props.allRoutes = generateRouteList();
    attachSuggestionInput();
  }

  function attachSuggestionInput() {
    $("label[for='route']").after(renderRouteInput());
  }

  function renderRouteInput() {
    return `
      <input type="text" name="route" placeholder="Enter your bus number" class="subscription-select-route station-input" data-valid="false" autocomplete="off"/>
      <div class="suggestion-container"></div>
      <i class="fa fa-check-circle valid-checkmark-icon"></i>
    `
  }

  function renderRouteSuggestion(route) {
    return `
    <div class="station-suggestion bus-route">${route}</div>
    `
  }

  function generateRouteList() {
    let routes = [];
    const $options = $("select.subscription-select-route").children();
    $options.each(function(i, option) {
      if (i !== 0) {
        let routeName = option.value
        routes.push(routeName);
      }
    });

    return routes;
  }

  function typeahead(event) {
    const query = event.target.value;

    if (query.length > 0) {
      const matchingRoutes = filterSuggestions(query);
      const suggestionElements = matchingRoutes.map(function(route) {
        return renderRouteSuggestion(route);
      });

      const $suggestionContainer = $('.suggestion-container');
      $suggestionContainer.html(suggestionElements);
    } else {
      unmountRouteSuggestions();
    }
  }

  function unmountRouteSuggestions() {
    $(`.bus-route`).remove();
  }

  function filterSuggestions(query) {
    const queryRegExp = new RegExp(query, "i");

    let matchingRoutes = props.allRoutes.filter(function(route) {
      return route.match(queryRegExp);
    });

    return matchingRoutes;
  }

  function validateRouteInput(routeName) {
    const $routeInput = $('.subscription-select-route');
    if (props.allRoutes.includes(routeName)) {
      $routeInput.attr("data-valid", true);
    } else {
      $routeInput.attr("data-valid", false);
    }
  }

  function pickFirstSuggestion(event) {
    const $routeInput = $('.subscription-select-route');
    const $firstSuggestion = $(`.bus-route`).first();

    if ($firstSuggestion.length) {
      const routeName = $firstSuggestion.text();
      $routeInput.val(routeName);
      validateRouteInput(routeName)
    }
    unmountRouteSuggestions();
  }

  function assignSuggestion(event) {
    const routeName = event.target.textContent;
    const $routeInput = $('.subscription-select-route');

    $routeInput.val(routeName);
    validateRouteInput(routeName)
    unmountRouteSuggestions();
  }

  $(document).on(
    "keyup", ".subscription-select-route", {}, typeahead);
  $(document).on(
    "keyup", ".subscription-select-route", {}, validateRouteInput);
  $(document).on(
    "focusout", ".subscription-select-route", {}, pickFirstSuggestion);
  $(document).on(
    "mousedown", ".bus-route", {}, assignSuggestion);
}
