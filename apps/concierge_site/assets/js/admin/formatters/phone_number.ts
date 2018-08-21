export const format = (phoneNumber: string) => {
  if (!phoneNumber) return null;

  return `${phoneNumber.slice(0, 3)}-${phoneNumber.slice(3, 6)}-${phoneNumber.slice(6)}`;
}

export const stripHyphens = (phoneNumber: string) => {
  const anythingButHyphensOrDigits = /[^-\d]/
  // If the input contains characters it isn't actually a phone number, so don't strip hyphens
  if (phoneNumber.match(anythingButHyphensOrDigits)) return phoneNumber;

  return phoneNumber.replace(/-/g, "")
}
