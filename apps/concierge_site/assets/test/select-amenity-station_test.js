import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';
import { simulateKeyUp, simulateKeyPress } from './utils';
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
  });

  describe("keypress handling for suggestions", () => {
    it("first suggestion is selected by default", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Quincy");

      simulateKeyUp($stationInput[0]);

      const $firstSuggestion = $(".amenity-station").first();
      const $lastSuggestion = $(".amenity-station").last();

      assert($firstSuggestion.is(".selected-suggestion"));
      assert.isFalse($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing the down arrow moves the selected suggestion down to the next suggestion", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Quincy");

      simulateKeyUp($stationInput[0]);
      simulateKeyPress($stationInput[0], 40);
      const $firstSuggestion = $(".amenity-station").first();
      const $lastSuggestion = $(".amenity-station").last();

      assert.isFalse($firstSuggestion.is(".selected-suggestion"));
      assert($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing the down arrow doesn't do anything if there aren't any more suggestions below", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Quincy");

      simulateKeyUp($stationInput[0]);
      simulateKeyPress($stationInput[0], 40);
      simulateKeyPress($stationInput[0], 40);
      const $firstSuggestion = $(".amenity-station").first();
      const $lastSuggestion = $(".amenity-station").last();

      assert.isFalse($firstSuggestion.is(".selected-suggestion"));
      assert($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing the up arrow moves the selected suggestion up to the previous suggestion", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Quincy");

      simulateKeyUp($stationInput[0]);
      simulateKeyPress($stationInput[0], 40);
      simulateKeyPress($stationInput[0], 38);
      const $firstSuggestion = $(".amenity-station").first();
      const $lastSuggestion = $(".amenity-station").last();

      assert($firstSuggestion.is(".selected-suggestion"));
      assert.isFalse($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing the up arrow doesn't do anything if there aren't any more suggestions above", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Quincy");

      simulateKeyUp($stationInput[0]);
      simulateKeyPress($stationInput[0], 38);
      const $firstSuggestion = $(".amenity-station").first();
      const $lastSuggestion = $(".amenity-station").last();

      assert($firstSuggestion.is(".selected-suggestion"));
      assert.isFalse($lastSuggestion.is(".selected-suggestion"));
    });

    it("pressing enter selects the highlighted suggestion", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Quincy");

      simulateKeyUp($stationInput[0]);
      simulateKeyPress($stationInput[0], 40);

      const $lastSuggestion = $(".amenity-station").last();
      assert($lastSuggestion.is(".selected-suggestion"));

      simulateKeyPress($stationInput[0], 13);

      const $selectedStations = $(".btn-selected-station")

      assert.equal($selectedStations[0].textContent.trim(), "Quincy Center")
    });
  });

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

    it("does not show prompt as a suggestion", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Select");

      simulateKeyUp($stationInput[0]);

      const $suggestions = $(".amenity-station")
      assert.lengthOf($suggestions, 0)
    });
  });

  describe("clicking on a suggestion", () => {
    it("adds a button with that choice to list of stops", () => {
      const $stationInput = $("input.subscription-select-amenity-station");
      $stationInput.val("Central");

      simulateKeyUp($stationInput[0])
      $(".amenity-station").first().mousedown();
      const $selectedStations = $(".btn-selected-station")

      assert.equal($selectedStations[0].textContent.trim(), "Central Square")
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
        <div class="form-group select-station select-amenity-station">
          <label for="station" class="station-input-label form-label">What stations do you use?</label>
          <div class="form-sub-label amenity-station-select-sub-label">Enter as many stations as you would like.</div>
          <select class="subscription-select subscription-select-amenity-station no-js">
            <option value="">Select a station</option>
            <optgroup label="Red Line">
              <option value="place-nqncy">North Quincy</option>
              <option value="place-qnctr">Quincy Center</option>
              <option value="place-central">Central Square</option>
            </optgroup>
            <optgroup label="Needham Line">
              <option value="place-rggl">Ruggles</option>
              <option value="place-bellevue">Bellevue</option>
            </optgroup>
          </select>
          <div class="selected-station-list amenity-station-list"></div>
          <input class="subscription-amenities-stops" id="subscription_stops" name="subscription[stops]" type="hidden" value="">
        </div>
      </form>
    </div>
    `
});
