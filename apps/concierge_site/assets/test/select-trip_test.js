import 'jsdom-global/register';
import jsdom from 'mocha-jsdom';
import { assert } from 'chai';
import selectTrip from '../js/select-trip';

describe("selectStation", function() {
  let $;

  before(function() {
    $ = jsdom.rerequire('jquery');
  });

  beforeEach(function() {
    $("body").append(tripSelectPageHtml);
    selectTrip($);
  });

  afterEach(function() {
    $("body > div").remove()
  });

  it("initially displays three trips including closest trip", () => {
    assert.sameMembers(getVisisbleTripNumbers(), ["10", "12", "14", "1", "3", "5"]);
  });

  it ("view more displays 3 more trips on both sides if available", () => {
    const $viewMore = $(".view-more-link");
    $viewMore[0].click();

    assert.sameMembers(getVisisbleTripNumbers(), ["4", "6", "8", "10", "12", "14", "16", "18", "20", "1", "3", "5"]);

    $viewMore[1].click();

    assert.sameMembers(getVisisbleTripNumbers(), ["4", "6", "8", "10", "12", "14", "16", "18", "20", "1", "3", "5", "7", "9", "11"]);
  });

  it ("view all displays all trips", () => {
    const $viewAll = $(".view-all-link");
    $viewAll[0].click();

    assert.sameMembers(getVisisbleTripNumbers(), ["2", "4", "6", "8", "10", "12", "14", "16", "18", "20", "1", "3", "5"]);

    $viewAll[1].click();

    assert.sameMembers(getVisisbleTripNumbers(), ["2", "4", "6", "8", "10", "12", "14", "16", "18", "20", "1", "3", "5", "7", "9", "11", "13", "15", "17", "19"]);
  });

  it ("view less collapses list to contain all selected trips if selected count > 1", () => {
    const $viewAll = $(".view-all-link");
    const $viewLess = $(".view-less-link");
    $viewAll[0].click();

    $("input[value=18]").click()
    $viewLess[0].click();

    assert.sameMembers(getVisisbleTripNumbers(), ["12", "14", "16", "18", "1", "3", "5"]);
  });

  it ("view less collapses list to checked trip and 2 surrounding if selected count == 1", () => {
    const $viewAll = $(".view-all-link");
    const $viewLess = $(".view-less-link");
    $viewAll[0].click();

    $("input[value=12]").click()
    $("input[value=4]").click()
    $viewLess[0].click();

    assert.sameMembers(getVisisbleTripNumbers(), ["2", "4", "6", "1", "3", "5"]);
  });

  it ("view less collapses to starting 3 trips if selected count is 0", () => {
    const $viewAll = $(".view-all-link");
    const $viewLess = $(".view-less-link");
    $viewAll[0].click();

    $("input[value=12]").click()
    $viewLess[0].click();

    assert.sameMembers(getVisisbleTripNumbers(), ["10", "12", "14", "1", "3", "5"]);
  });

  const tripSelectPageHtml = `
    <div class="select-trip-number">
      <form class="trip-info-form commuter-rail">
        <div class="trip-select-list-header">Depart</div>
        <div class="trip-select-list">
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_2" value="2" false />
            <label for="subscription_trip_2">Franklin Line 2 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_4" value="4" false />
            <label for="subscription_trip_4">Franklin Line 4 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_6" value="6" false />
            <label for="subscription_trip_6">Franklin Line 6 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_8" value="8" false />
            <label for="subscription_trip_8">Franklin Line 8 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_10" value="10" false />
            <label for="subscription_trip_10">Franklin Line 10 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option closest-trip">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_12" value="12" checked />
            <label for="subscription_trip_12">Franklin Line 12 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_14" value="14" false />
            <label for="subscription_trip_14">Franklin Line 14 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_16" value="16" false />
            <label for="subscription_trip_16">Franklin Line 16 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_18" value="18" false />
            <label for="subscription_trip_18">Franklin Line 18 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_20" value="20" false />
            <label for="subscription_trip_20">Franklin Line 20 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-toggle-links js">
            <span class="view-more-link js">View More +</span>
            <span class="view-less-link js">View Less -</span>
            <span class="view-all-link js">View All +</span>
          </div>
        </div>
        <div class="trip-select-list-header">Return</div>
        <div class="trip-select-list">
          <div class="trip-option closest-trip">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_1" value="1" checked />
            <label for="subscription_trip_1">Franklin Line 1 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_3" value="3" false />
            <label for="subscription_trip_3">Franklin Line 3 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_5" value="5" false />
            <label for="subscription_trip_5">Franklin Line 5 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_7" value="7" false />
            <label for="subscription_trip_7">Franklin Line 7 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_9" value="9" false />
            <label for="subscription_trip_9">Franklin Line 9 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_11" value="11" false />
            <label for="subscription_trip_11">Franklin Line 11 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_13" value="13" false />
            <label for="subscription_trip_13">Franklin Line 13 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_15" value="15" false />
            <label for="subscription_trip_15">Franklin Line 15 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_17" value="17" false />
            <label for="subscription_trip_17">Franklin Line 17 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-option">
            <input type="checkbox" name="subscription[trips][], id="subscription_trip_19" value="19" false />
            <label for="subscription_trip_19">Franklin Line 19 | Departs Morton Street at 5:47am, arrives at South Station at 6:09am
          </div>
          <div class="trip-toggle-links js">
            <span class="view-more-link js">View More +</span>
            <span class="view-less-link js">View Less -</span>
            <span class="view-all-link js">View All +</span>
          </div>
        </div>
      </form>
    </div>
    `

  function getVisisbleTripNumbers(){
    const $visibleTrips = $(".trip-select-list").children(".trip-option").not(".hidden");
    return $visibleTrips.map(function(_, trip){
      return $(trip).children("input").val();
    }).get();
  }
});
