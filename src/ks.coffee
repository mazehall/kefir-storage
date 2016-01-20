_r = require 'kefir'

_stream = null
_store = {}

model = {}
model.linesMax = 300
model.uniqueness = true

# resolve references
model._cloneObject = (obj) -> JSON.parse(JSON.stringify(obj))

# starts the object observation
model._initStream = () ->
  _stream = _r.stream (emitter) ->
    Object.observe _store, (properties) ->
      for property in properties
        model._emitProperty emitter, property

model._isTypeArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

model._isUnique = (propertyName, value) -> JSON.stringify(value) != JSON.stringify(_store[propertyName])

# emit observed property
model._emitProperty = (emitter, property) ->
  emit =
    name: property.name
    value: property.object[property.name]

  if property.oldValue then emit.oldValue = property.oldValue  else emit.oldValue = undefined

  emitter.emit emit

model._set = (propertyName, value, unique) ->
  unique = if typeof unique == 'undefined' then model.uniqueness else unique

  # uniqueness comparison
  return true if unique && ! model._isUnique propertyName, value

  _store[propertyName] = model._cloneObject value
  return true

model.get = (propertyName) ->
  return null if !(!!propertyName)
  return undefined if typeof _store[propertyName] == "undefined"

  return model._cloneObject _store[propertyName]

model.set = (propertyName, value, unique) ->
  return null if !(!!propertyName)
  value = null if typeof value == "undefined"

  model._set propertyName, value, unique

model.setChildProperty = (propertyName, childName, value, unique) ->
  return false if !(!!propertyName) || !(!!childName) || model._isTypeArray(_store[propertyName]) || !(typeof _store[propertyName] == "object" || typeof _store[propertyName] == "undefined")
  value = null if typeof value == "undefined"

  if typeof _store[propertyName] == "undefined"
    property = {}
    property[childName] = value
  else
    property = model.get propertyName
    property[childName] = value

  model._set propertyName, property, unique

# overwrites existing non arrays
model.log = (propertyName, value) ->
  return false if !(!!propertyName)

  property = if model._isTypeArray _store[propertyName] then model.get propertyName else []
  property.push value

  if model.linesMax? && property.length > model.linesMax
    property.shift()

  model._set propertyName, property, false

model.stream = -> _stream

model.fromProperty = (propertyName) ->
  _stream
  .filter (x) ->
    x.name? && x.name == propertyName

model.fromRegex = (regexp) ->
  _stream
  .filter (x) ->
    x.name? && x.name.match regexp

model._initStream()
module.exports = model