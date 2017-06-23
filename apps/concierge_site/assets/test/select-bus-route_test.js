import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';
import selectBusRoute from '../js/select-bus-route';

describe("selectBusRoute", function() {
  let $;

  before(function() {
    $ = jsdom.rerequire('jquery');
  });

  beforeEach(function() {
    $("body").append(tripInfoPageHtml);
    selectBusRoute($);
  });

  afterEach(function() {
    $("body > div").remove()
  });

  describe("immediate changes upon page load", () => {
    it("adds text inputs to the page for station entry", () => {
      const $suggestionContainers = $(".suggestion-container");
      const $routeInput = $("input.subscription-select-route");

      assert.lengthOf($suggestionContainers, 1);
      assert.lengthOf($routeInput, 1);
    });
  });

  describe("type ahead suggestions", () => {
    it("adds matching routes to the page when the user types a name into the input field", () => {
      const $routeInput = $(".subscription-select-route")
      $routeInput.val("Silver Line SL1 - Inbound");
      const $suggestionContainer = $(".suggestion-container");

      simulateKeyUp($routeInput[0])

      const $suggestions = $(".bus-route")
      const routeSuggestion = $suggestions.first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(routeSuggestion, "Silver Line SL1 - Inbound")
    });

    it("shows partially matching routes", () => {
      const $routeInput = $(".subscription-select-route")
      $routeInput.val("S");
      const $suggestionContainer = $(".suggestion-container");

      simulateKeyUp($routeInput[0])

      const $suggestions = $(".bus-route")
      const routeSuggestion = $suggestions.first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(routeSuggestion, "Silver Line SL1 - Inbound")
    });


    it("matches case insensitively", () => {
      const $routeInput = $(".subscription-select-route")
      $routeInput.val("silver");
      const $suggestionContainer = $(".suggestion-container");

      simulateKeyUp($routeInput[0])

      const $suggestions = $(".bus-route")
      const routeSuggestion = $suggestions.first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(routeSuggestion, "Silver Line SL1 - Inbound")
    });
  });

  describe("clicking on a suggestion", () => {
    it("populates the route input field with the route full name", () => {
      const $routeInput = $("input.subscription-select-route");
      $routeInput.val("Silver");
      const $suggestionContainer = $(".suggestion-container");

      simulateKeyUp($routeInput[0])

      $(".bus-route").first().mousedown();

      assert.equal($routeInput.val(), "Silver Line SL1 - Inbound");
    });
  })

  describe("route input losing focus", () => {
    it("populates the route input field with the first suggestion", () => {
      const $routeInput = $("input.subscription-select-route");
      $routeInput.val("Silver");
      const $suggestionContainer = $(".suggestion-container");

      $routeInput.focus();
      simulateKeyUp($routeInput[0])
      $("input.subscription-select-route").first().blur()

      assert.equal($routeInput.val(), "Silver Line SL1 - Inbound");
    });

    it("does nothing when there are no suggestions in the origin field", () => {
      const $routeInput = $("input.subscription-select-route");
      $routeInput.val("abc123");
      const $suggestionContainer = $(".suggestion-container");

      $routeInput.focus();
      simulateKeyUp($routeInput[0])
      $("input.subscription-select-route").focus()

      assert.equal($routeInput.val(), "abc123");
    });
  });

  describe("validation", () => {
    it("changes the data-valid attribute of the route input to true when the value exactly matches a route name", () => {
      const $routeInput = $("input.subscription-select-route");
      $routeInput.val("Silver Line SL1 - Inbound");
      simulateKeyUp($routeInput[0])
      $(".bus-route").first().mousedown();

      assert.equal("true", $routeInput.attr("data-valid"));
    });

    it("changes the data-valid attribute of the route input to false when the value does not match a route name", () => {
      const $routeInput = $("input.subscription-select-route");
      $routeInput.val("abc123");
      simulateKeyUp($routeInput[0])
      $(".bus-route").first().mousedown();

      assert.equal("false", $routeInput.attr("data-valid"));
    });
  });

  describe("logo", () => {
    it("renders the bus logo", () => {
      const $routeInput = $(".subscription-select-route")
      $routeInput.val("57");

      simulateKeyUp($routeInput[0])
      const logo = $('.bus-route').first().children()[1].innerHTML

      assert.include(logo, 'icon-bus')
    });
  });

  const tripInfoPageHtml = `
    <div class="enter-trip-info">
      <form>
        <div class="form-group select-route">
          <label for="route" class="station-input-label form-label">Origin</label>
          <select class="subscription-select-route no-js">
            <option value="">Enter your bus number</option>
            <option value="Silver Line SL1 - Inbound">Silver Line SL1 - Inbound</option>
            <option value="Route 57 - Outbound">Route 57 - Outbound</option>
          </select>
        </div>
      </form>
    </div>
    `

  function simulateKeyUp(target) {
    const event = document.createEvent("HTMLEvents");
    event.initEvent("keyup", true, true);
    target.dispatchEvent(event);
  }
});
