var argv = require('yargs').argv;
var juice = require('juice');
var fs = require('fs');

function read(file) {
  if (fs.existsSync(file)){
    return fs.readFileSync(file, 'utf8');
  } else {
    return fs.readFileSync(argv.defaultCssFile, 'utf8');
  }
}

var css = read(argv.globalCssFile) + read(argv.cssFile);
var html = read(argv.htmlFile);
var options = {};

console.log(juice.inlineContent(html, css, options));
