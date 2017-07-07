export default function($) {
  $ = $ || window.jQuery;

  function setToggleableSectionDisplay() {
    const $section = $(this).parents(".my-account-section");

    console.log($section.text());

    const $toggleableSection = $(".supporting-info-section", $section);
    const $inputTrue = $("input[value='true']", $section);
    const $inputFalse = $("input[value='false']", $section);

    if ($inputTrue.prop("checked")) {
      $toggleableSection.toggleClass("toggleable", false)
    } else if ($inputFalse.prop("checked")) {
      $toggleableSection.toggleClass("toggleable", true)
    }
  }

  $(document).on("change", ".my-account-radio-button", setToggleableSectionDisplay);
}
