var _r, _store, _stream, model;

_r = require('kefir');

_stream = null;

_store = {};

model = {};

model.linesMax = 300;

model.uniqueness = true;

model._cloneObject = function(obj) {
  return JSON.parse(JSON.stringify(obj));
};

model._initStream = function() {
  return _stream = _r.stream(function(emitter) {
    return Object.observe(_store, function(properties) {
      var i, len, property, results;
      results = [];
      for (i = 0, len = properties.length; i < len; i++) {
        property = properties[i];
        results.push(model._emitProperty(emitter, property));
      }
      return results;
    });
  });
};

model._isTypeArray = Array.isArray || function(value) {
  return {}.toString.call(value) === '[object Array]';
};

model._isUnique = function(propertyName, value) {
  return JSON.stringify(value) !== JSON.stringify(_store[propertyName]);
};

model._emitProperty = function(emitter, property) {
  var emit;
  emit = {
    name: property.name,
    value: property.object[property.name]
  };
  if (property.oldValue) {
    emit.oldValue = property.oldValue;
  } else {
    emit.oldValue = void 0;
  }
  return emitter.emit(emit);
};

model._set = function(propertyName, value, unique) {
  unique = typeof unique === 'undefined' ? model.uniqueness : unique;
  if (unique && !model._isUnique(propertyName, value)) {
    return true;
  }
  _store[propertyName] = model._cloneObject(value);
  return true;
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

model.set = function(propertyName, value, unique) {
  if (!(!!propertyName)) {
    return null;
  }
  if (typeof value === "undefined") {
    value = null;
  }
  return model._set(propertyName, value, unique);
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
  } else {
    property = model.get(propertyName);
    property[childName] = value;
  }
  return model._set(propertyName, property, unique);
};

model.log = function(propertyName, value) {
  var property;
  if (!(!!propertyName)) {
    return false;
  }
  property = model._isTypeArray(_store[propertyName]) ? model.get(propertyName) : [];
  property.push(value);
  if ((model.linesMax != null) && property.length > model.linesMax) {
    property.shift();
  }
  return model._set(propertyName, property, false);
};

model.stream = function() {
  return _stream;
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

model._initStream();

module.exports = model;
