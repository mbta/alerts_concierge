export default function($) {
  $ = $ || window.jQuery;

  const $selectTripNumberContainer = $("div.select-trip-number")[0];
  if ($selectTripNumberContainer === undefined){
    return;
  }

  const $viewAllLinks = $(".view-all-link");
  const $viewLessLinks = $(".view-less-link");
  const $viewMoreLinks = $(".view-more-link");

  function initialize(){
    const $closestTrips = $(".closest-trip");

    $closestTrips.each(function(_, trip){
      showStartingTrips(trip);
    });
    $viewAllLinks.removeClass("hidden");
    $viewLessLinks.addClass("hidden");
    $viewMoreLinks.removeClass("hidden");
  }

  function showAllTrips(event){
    const $viewAllLink = $(event.target);

    $viewAllLink.parent().siblings(".trip-option").removeClass("hidden");
    $viewAllLink.siblings(".view-more-link").addClass("hidden");
    $viewAllLink.siblings(".view-less-link").removeClass("hidden");
    $viewAllLink.addClass("hidden");
  }

  function showLessTrips(event){
    const $viewLessLink = $(event.target);
    const $checkedTrips = $viewLessLink.parent().siblings(".trip-option").children("input:checked").parent();

    if ($checkedTrips.length > 1) {
      $checkedTrips.first().prevAll(".trip-option").addClass("hidden");
      $checkedTrips.last().nextAll(".trip-option").addClass("hidden");
    } else if ($checkedTrips.length === 1) {
      showStartingTrips($checkedTrips[0]);
    } else {
      showStartingTrips($viewLessLink.parent().siblings(".closest-trip").first());
    }
    $viewLessLink.addClass("hidden");
    $viewLessLink.siblings(".view-more-link").removeClass("hidden")
    $viewLessLink.siblings(".view-all-link").removeClass("hidden")
  }

  function showMoreTrips(event){
    const $viewMoreLink = $(event.target);
    const hiddenTrips = $viewMoreLink.parent().siblings(".trip-option.hidden");

    $viewMoreLink.parent().siblings(".trip-option").not(".hidden").last().nextAll(".trip-option").slice(0, 3).removeClass("hidden");
    $viewMoreLink.parent().siblings(".trip-option").not(".hidden").first().prevAll(".trip-option").slice(0, 3).removeClass("hidden");
    if (hiddenTrips.length === 0){
      $viewMoreLink.parent().siblings(".view-all-link").addClass("hidden");
      $viewMoreLink.addClass("hidden");
    } else {
      $viewMoreLink.siblings(".view-less-link").removeClass("hidden");
    }
  }

  function showStartingTrips(trip){
    const $earlierTrips = $(trip).prevAll(".trip-option").slice(0, 2);
    const $laterTrips = $(trip).nextAll(".trip-option").slice(0, 2);

    $(trip).siblings(".trip-option").addClass("hidden");
    if ($earlierTrips.length === 0){
      $laterTrips.removeClass("hidden");
    } else if ($laterTrips.length === 0){
      $earlierTrips.removeClass("hidden");
    } else {
      $laterTrips.first().removeClass("hidden");
      $earlierTrips.first().removeClass("hidden");
    }
  }

  $viewAllLinks.click(showAllTrips);
  $viewLessLinks.click(showLessTrips);
  $viewMoreLinks.click(showMoreTrips);
  initialize();
}
