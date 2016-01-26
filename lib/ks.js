var _r, _store, _stream, model;

_r = require('kefir');

_store = {};

_stream = _r.pool();

model = {};

model.linesMax = 300;

model.uniqueness = true;

model._cloneObject = function(obj) {
  return JSON.parse(JSON.stringify(obj));
};

model._isTypeArray = Array.isArray || function(value) {
  return {}.toString.call(value) === '[object Array]';
};

model._isSame = function(val1, val2) {
  return JSON.stringify(val1) === JSON.stringify(val2);
};

model._emit = function(propertyName, value) {
  return _stream.plug(_r.constant({
    name: propertyName,
    value: value
  }));
};

model.fromProperty = function(propertyName) {
  return _stream.filter(function(x) {
    return (x.name != null) && x.name === propertyName;
  });
};

model.fromRegex = function(regexp) {
  return _stream.filter(function(x) {
    return (x.name != null) && x.name.match(regexp);
  });
};

model.get = function(propertyName) {
  if (!(!!propertyName)) {
    return null;
  }
  if (typeof _store[propertyName] === "undefined") {
    return void 0;
  }
  return model._cloneObject(_store[propertyName]);
};

model.getChildProperty = function(propertyName, childName) {
  if (!(!!propertyName) || !(!!childName)) {
    return null;
  }
  if (typeof _store[propertyName] !== "object" || typeof _store[propertyName][childName] === "undefined") {
    return void 0;
  }
  return model._cloneObject(_store[propertyName][childName]);
};

model.getStream = function() {
  return _stream;
};

model.log = function(propertyName, value) {
  if (!(!!propertyName)) {
    return false;
  }
  if (typeof value === "undefined") {
    value = null;
  }
  if (!model._isTypeArray(_store[propertyName])) {
    return model.set(propertyName, [value], false);
  }
  _store[propertyName].push(value);
  if ((model.linesMax != null) && _store[propertyName].length > model.linesMax) {
    _store[propertyName].shift();
  }
  return model._emit(propertyName, model._cloneObject(_store[propertyName]));
};

model.set = function(propertyName, value, unique) {
  if (!(!!propertyName)) {
    return null;
  }
  if (typeof value === "undefined") {
    value = null;
  }
  unique = typeof unique === 'undefined' ? model.uniqueness : unique;
  if (unique && model._isSame(_store[propertyName], value)) {
    return true;
  }
  _store[propertyName] = model._cloneObject(value);
  return model._emit(propertyName, value);
};

model.setChildProperty = function(propertyName, childName, value, unique) {
  var property;
  if (!(!!propertyName) || !(!!childName) || model._isTypeArray(_store[propertyName]) || !(typeof _store[propertyName] === "object" || typeof _store[propertyName] === "undefined")) {
    return false;
  }
  if (typeof value === "undefined") {
    value = null;
  }
  if (typeof _store[propertyName] === "undefined") {
    property = {};
    property[childName] = value;
    return model.set(propertyName, property);
  }
  unique = typeof unique === 'undefined' ? model.uniqueness : unique;
  if (unique && model._isSame(_store[propertyName][childName], value)) {
    return true;
  }
  _store[propertyName][childName] = model._cloneObject(value);
  return model._emit(propertyName, _store[propertyName]);
};

module.exports = model;
