_r = require 'kefir'

_store = {}
_stream = _r.pool()


model = {}
model.linesMax = 300
model.uniqueness = true


# resolve references
model._cloneObject = (obj) ->
  JSON.parse(JSON.stringify(obj))

model._isTypeArray = Array.isArray || ( value ) ->
  return {}.toString.call( value ) is '[object Array]'

model._isSame = (val1, val2) ->
  JSON.stringify(val1) == JSON.stringify(val2)

model._emit = (propertyName, value) ->
  _stream.plug _r.constant {name: propertyName, value: value}

model.fromProperty = (propertyName) ->
  _stream.filter (x) ->
    x.name? && x.name == propertyName

model.fromRegex = (regexp) ->
  _stream.filter (x) ->
    x.name? && x.name.match regexp

model.get = (propertyName) ->
  return null if !(!!propertyName)
  return undefined if typeof _store[propertyName] == "undefined"

  model._cloneObject _store[propertyName]

model.getStream = ->
  _stream

# overwrites existing non arrays
model.log = (propertyName, value) ->
  return false if !(!!propertyName)
  value = null if typeof value == "undefined"
  return model.set propertyName, [value], false if ! model._isTypeArray _store[propertyName]

  _store[propertyName].push value
  _store[propertyName].shift() if model.linesMax? && _store[propertyName].length > model.linesMax

  model._emit propertyName, model._cloneObject _store[propertyName]

model.set = (propertyName, value, unique) ->
  return null if !(!!propertyName)
  value = null if typeof value == "undefined"

  # uniqueness comparison
  unique = if typeof unique == 'undefined' then model.uniqueness else unique
  return true if unique && model._isSame _store[propertyName], value

  # set without references
  _store[propertyName] = model._cloneObject value

  model._emit propertyName, value

model.setChildProperty = (propertyName, childName, value, unique) ->
  return false if !(!!propertyName) || !(!!childName) || model._isTypeArray(_store[propertyName]) || !(typeof _store[propertyName] == "object" || typeof _store[propertyName] == "undefined")
  value = null if typeof value == "undefined"

  if typeof _store[propertyName] == "undefined"
    property = {}
    property[childName] = value
    return model.set propertyName, property

  # uniqueness comparison
  unique = if typeof unique == 'undefined' then model.uniqueness else unique
  return true if unique && model._isSame _store[propertyName][childName], value

  _store[propertyName][childName] = model._cloneObject value

  model._emit propertyName, _store[propertyName]



module.exports = model