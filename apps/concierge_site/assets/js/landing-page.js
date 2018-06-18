export default $ => {
  $ = $ || window.jQuery;

  // Don't apply label animations on smaller screens
  if ($(window).width() < 1089) return;

  $("body.landing-page input.form-control").label_better({
    // position: "top", // This will let you define the position where the label will appear when the user clicked on the input fields. Acceptable options are "top", "bottom", "left" and "right". Default value is "top".
    animationTime: 200, // This will let you control the animation speed when the label appear. This option accepts value in milliseconds. The default value is 500.
    // easing: "ease-in-out", // This option will let you define the CSS easing you would like to see animating the label. The option accepts all default CSS easing such as "linear", "ease" etc. Another extra option is you can use is "bounce". The default value is "ease-in-out".
    offset: 19, // You can add more spacing between the input and the label. This option accepts value in pixels (without the unit). The default value is 20.
    hidePlaceholderOnFocus: false // The default placeholder text will hide on focus
  });
  $("body.landing-page label.form__label").hide();
};
