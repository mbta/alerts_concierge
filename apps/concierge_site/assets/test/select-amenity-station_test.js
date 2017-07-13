import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';
import selectAmenityStation from '../js/select-amenity-station';

describe("selectAmenityStation", function() {
  let $;

  before(function() {
    $ = jsdom.rerequire('jquery');
  });

  beforeEach(function() {
    $("body").append(tripInfoPageHtml);
    selectAmenityStation($);
  });

  afterEach(function() {
    $("body > div").remove()
  });


  describe("clicking on a chosen station", () => {
    it("removes the button from the list", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Central");
      simulateKeyUp($stationInput[0]);
      let suggestions = $(".amenity-station");
      $(".amenity-station").first().mousedown();
      $(".btn-selected-station").first().mousedown();

      let list = $('.selected-station-list.amenity-station-list')

      assert.lengthOf(list.first().children(), 0)
    })
  })

  describe("immediate changes upon page load", () => {
    it("adds text inputs to the page for station entry", () => {
      const $suggestionContainers = $(".suggestion-container");
      const $stationInput = $("input.subscription-select-amenity-station");

      assert.lengthOf($suggestionContainers, 1);
      assert.lengthOf($stationInput, 1);
    });
  });

  describe("type ahead suggestions", () => {
    it("adds matching stops to the page when the user types a name into the input field", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Central Square");

      simulateKeyUp($stationInput[0]);

      const $suggestions = $(".amenity-station")
      const routeSuggestion = $suggestions.first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(routeSuggestion, "Central Square")
    });

    it("shows partially matching stops", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Central");

      simulateKeyUp($stationInput[0]);

      const $suggestions = $(".amenity-station")
      const routeSuggestion = $suggestions.first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(routeSuggestion, "Central Square")
    });

    it("matches case insensitively", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("central square");

      simulateKeyUp($stationInput[0]);

      const $suggestions = $(".amenity-station")
      const routeSuggestion = $suggestions.first().text();

      assert.lengthOf($suggestions, 1)
      assert.include(routeSuggestion, "Central Square")
    });
  });

  describe("clicking on a suggestion", () => {
    it("adds a button with that choice to list of stops", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Central");

      simulateKeyUp($stationInput[0])
      $(".amenity-station").first().mousedown();
      const $selectedStations = $(".btn-selected-station")

      assert.equal($selectedStations[0].textContent, "Central Square")
    });

    it("removes the option from the possible suggestions", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Central");

      simulateKeyUp($stationInput[0]);
      let suggestions = $(".amenity-station");

      assert.lengthOf(suggestions, 1);

      $(".amenity-station").first().mousedown();
      suggestions = $(".amenity-station");

      assert.lengthOf(suggestions, 0);
    })
  })


  describe("route input losing focus", () => {
    it("clears removes suggestions", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("abc123");

      $stationInput.focus();
      simulateKeyUp($stationInput[0]);
      $("input.subscription-select-route").focus();
      const $suggestions = $("amenity-station");

      assert.lengthOf($suggestions, 0);
    });
  });

  const tripInfoPageHtml = `
    <div class="enter-trip-info">
      <form class="trip-info-form amenities">
        <div class="form-group select-station">
          <label for="station" class="station-input-label form-label">Select Individual Stations</label>
          <select class="subscription-select subscription-select-amenity-station no-js">
            <option value="">Select a station</option>
            <optgroup label="Red Line">
              <option value="place-nquincy">North Quincy</option>
              <option value="place-central">Central Square</option>
            </optgroup>
            <optgroup label="Needham Line">
              <option value="place-rggl">Ruggles</option>
              <option value="place-bellevue">Bellevue</option>
            </optgroup>
          </select>
          <div class="selected-station-list amenity-station-list"></div>
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
