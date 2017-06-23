import filterSuggestions from './filter-suggestions';

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
      <input type="text" name="route" placeholder="Enter your bus number" class="subscription-select subscription-select-route station-input" data-valid="false" autocomplete="off"/>
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
      const matchingRoutes = filterSuggestions(query, props.allRoutes);
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

  function validateRouteInput(routeName) {
    const $routeInput = $('.subscription-select-route');
    $routeInput.attr("data-valid", props.allRoutes.includes(routeName));
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
