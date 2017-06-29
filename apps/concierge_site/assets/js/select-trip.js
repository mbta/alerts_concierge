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
      showSurroundingTrips(trip);
    });

    $viewAllLinks.each(function(_, link){
      showHideLinks($(link));
    });
  }

  function showAllTrips(event){
    const $viewAllLink = $(event.target);

    relatedTrips($viewAllLink).removeClass("hidden");

    showHideLinks($viewAllLink);
  }

  function showLessTrips(event){
    const $viewLessLink = $(event.target);
    const $checkedTrips = relatedTrips($viewLessLink).children("input:checked").parent();

    if ($checkedTrips.length > 1) {
      $checkedTrips.first().prevAll(".trip-option").addClass("hidden");
      $checkedTrips.last().nextAll(".trip-option").addClass("hidden");
    } else if ($checkedTrips.length === 1) {
      showSurroundingTrips($checkedTrips[0]);
    } else {
      showSurroundingTrips($viewLessLink.parent().siblings(".closest-trip").first());
    }

    showHideLinks($viewLessLink);
  }

  function showMoreTrips(event){
    const $viewMoreLink = $(event.target);
    const hiddenTrips = relatedHiddenTrips($viewMoreLink);
    const $visibleTrips = relatedVisibleTrips($viewMoreLink);

    $visibleTrips.last().nextAll(".trip-option").slice(0, 3).removeClass("hidden");
    $visibleTrips.first().prevAll(".trip-option").slice(0, 3).removeClass("hidden");

    showHideLinks($viewMoreLink);
  }

  function showSurroundingTrips(trip){
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

  function showHideLinks($link){
    const $viewAllLink = $link.parent().children(".view-all-link");
    const $viewLessLink = $link.parent().children(".view-less-link");
    const $viewMoreLink = $link.parent().children(".view-more-link");
    $viewAllLink.toggleClass("hidden", !haveHiddenTrips($link));
    $viewLessLink.toggleClass("hidden", !haveCollapsableTrips($link));
    $viewMoreLink.toggleClass("hidden", !haveHiddenTrips($link));
  }

  function relatedTrips($link){
    return $link.parent().siblings(".trip-option");
  }

  function relatedVisibleTrips($link){
    return relatedTrips($link).not(".hidden");
  }

  function relatedHiddenTrips($link){
    return $link.parent().siblings(".trip-option.hidden");
  }

  function haveHiddenTrips($link){
    return relatedHiddenTrips($link).length > 0;
  }

  function haveCollapsableTrips($link){
    return relatedVisibleTrips($link).length > 3;
  }

  $viewAllLinks.click(showAllTrips);
  $viewLessLinks.click(showLessTrips);
  $viewMoreLinks.click(showMoreTrips);
  initialize();
}
