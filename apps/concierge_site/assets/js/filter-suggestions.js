export default function(query, collection, prop = undefined) {
  const queryRegExp = new RegExp(query, "i");

  let matching = collection.filter(function(element) {
    if (prop === undefined) {
      return element.match(queryRegExp);
    } else {
      return element[prop].match(queryRegExp);
    }
  });

  return matching;
}
