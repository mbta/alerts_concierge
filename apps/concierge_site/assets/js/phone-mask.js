import masker from "maskerjs";

const telMask = new masker(
  ["___-____", "(___) ___-____", "+_-___-___-____"],
  /^[0-9]$/
);

export default () => {
  [...document.querySelectorAll("input[type='tel']")].forEach(input =>
    telMask.mask(input)
  );
};
