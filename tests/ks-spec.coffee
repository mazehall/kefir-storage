'use strict';

rewire = require "rewire"

model = null
data =
  "null": null
  "bTrue": true
  "bFalse": false
  "string": "I am string"

  "object":
    "null": null
    "bTrue": true
    "bFalse": false
    "string": "I am string too"
    "object": {"key": "val1", "key": "val2"}
    "array": [ "aval1", "aval2"]

  "array": [
    null
    true
    false
    "I am string too"
    {"key": "val1", "key": "val2"}
    ["aval1", "aval2"]
  ]

# set cloned object to avoid object referencing issues
cloneObject = (obj) -> JSON.parse(JSON.stringify(obj))

setup = ->
  model = rewire "../src/ks.coffee"
  model.__set__ '_store', cloneObject data


describe '_cloneObject', ->

  beforeEach -> setup()

  it "Should remove reference", ->
    obj = {"test1": "test", "test2": "test"}
    clone = model._cloneObject obj

    expect(clone == obj).toBeFalsy()

  it "Should still contain the content", ->
    obj = {"test1": "test", "test2": "test"}
    clone = model._cloneObject obj

    expect(JSON.stringify(clone)).toEqual(JSON.stringify(obj))


describe 'isTypeArray', ->
  _isArray = null

  beforeEach ->
    setup()
    _isArray = Array.isArray if Array.isArray

  afterEach -> Array.isArray = _isArray if _isArray

  it "Should return true", ->
    expect(model._isTypeArray []).toBeTruthy()
    expect(model._isTypeArray new Array).toBeTruthy()
    expect(model._isTypeArray data.array).toBeTruthy()
    expect(model._isTypeArray data.object.array).toBeTruthy()

  it "Should return false", ->
    expect(model._isTypeArray data.null).toBeFalsy()
    expect(model._isTypeArray data.bTrue).toBeFalsy()
    expect(model._isTypeArray data.string).toBeFalsy()
    expect(model._isTypeArray data.object).toBeFalsy()
    expect(model._isTypeArray data.array[4]).toBeFalsy()

  it "Should return true without isArray", ->
    return if ! Array.isArray
    delete Array.isArray

    expect(model._isTypeArray []).toBeTruthy()
    expect(model._isTypeArray new Array).toBeTruthy()
    expect(model._isTypeArray data.array).toBeTruthy()
    expect(model._isTypeArray data.object.array).toBeTruthy()

  it "Should return false without isArray", ->
    return if ! Array.isArray
    delete Array.isArray

    expect(model._isTypeArray data.null).toBeFalsy()
    expect(model._isTypeArray data.bTrue).toBeFalsy()
    expect(model._isTypeArray data.string).toBeFalsy()
    expect(model._isTypeArray data.object).toBeFalsy()
    expect(model._isTypeArray data.array[4]).toBeFalsy()


describe '_isSame', ->

  beforeEach -> setup()

  it "Should return false", ->
    expect(model._isSame(data.null, 'null')).toBeFalsy()
    expect(model._isSame(data.bTrue, false)).toBeFalsy()
    expect(model._isSame(data.string, "you are string")).toBeFalsy()
    expect(model._isSame(data.object, ["test", "test2"])).toBeFalsy()
    expect(model._isSame(data.array, {some: "more"})).toBeFalsy()

  it "Should return false so duplicate", ->
    for key, value of data
      expect(model._isSame(data[key], value)).toBeTruthy()


describe '_emit', ->

  beforeEach ->
    setup()
    model.__set__ '_r',
      constant: jasmine.createSpy('kefir.constant').andCallFake (x) -> x
    model.__set__ '_stream',
      plug: jasmine.createSpy('stream.plug').andCallFake ->

  it "should call kefir.constant", ->
    propertyName = 'string'
    value = {test: 'something'}

    model._emit propertyName, value

    expect(model.__get__('_r').constant).toHaveBeenCalledWith({name: propertyName, value: value})

  it "should call stream.plug", ->
    propertyName = 'string'
    value = {test: 'something'}

    model._emit propertyName, value

    expect(model.__get__('_stream').plug).toHaveBeenCalledWith({name: propertyName, value: value})


describe 'get', ->

  beforeEach -> setup()

  it "Should return null", ->
    expect(model.get 'null').toBeNull()

  it "Should return boolean true", ->
    expect(model.get 'bTrue').toBe(true)

  it "Should return boolean false", ->
    expect(model.get 'bFalse').toBe(false)

  it "Should return correct string", ->
    expect(model.get 'string').toBe(data.string)

  it "Should return complete object", ->
    expect(model.get 'object').toEqual(data.object)

  it "Should return complete array", ->
    expect(model.get 'array').toEqual(data.array)

  it "object changes should not change the storage data through object reference", ->
    objectData = model.get 'object'
    objectData.string = "Changed string"
    objectData.something = "new property"

    expect(model.__get__ '_store').toEqual(data)

  it "Should fail when no property given", ->
    expect(model.get '').toBeFalsy()
    expect(model.get null).toBeFalsy()

  it "Should return undefined if property does not exist", ->
    expect(model.get 'entropy').toBeUndefined()

describe 'getChildProperty', ->

  beforeEach -> setup()

  it "Should return null", ->
    expect(model.getChildProperty 'object', 'null').toBeNull()

  it "Should return boolean true", ->
    expect(model.getChildProperty 'object', 'bTrue').toBe(true)

  it "Should return boolean false", ->
    expect(model.getChildProperty 'object', 'bFalse').toBe(false)

  it "Should return correct string", ->
    expect(model.getChildProperty 'object', 'string').toBe(data.object.string)

  it "Should return complete object", ->
    expect(model.getChildProperty 'object', 'object').toEqual(data.object.object)

  it "Should return complete array", ->
    expect(model.getChildProperty 'object', 'array').toEqual(data.object.array)

  it "object changes should not change the storage data through object reference", ->
    objectData = model.getChildProperty 'object', 'object'
    objectData.string = "Changed string"
    objectData.something = "new property"

    expect(model.__get__ '_store').toEqual(data)

  it "Should fail when no property given", ->
    expect(model.getChildProperty '', 'something').toBeFalsy()
    expect(model.getChildProperty null, 'somehting').toBeFalsy()

    expect(model.getChildProperty 'object', '').toBeFalsy()
    expect(model.getChildProperty 'object', null).toBeFalsy()

  it "Should return undefined if property does not exist", ->
    expect(model.getChildProperty 'object', 'entropy').toBeUndefined()

  it "Should work with arrays", ->
    expect(model.getChildProperty 'array', 3).toBe('I am string too')
    expect(model.getChildProperty 'array', 'noNumericKey').toBe(undefined)


describe 'log', ->

  beforeEach ->
    setup()
    spyOn(model, 'set').andCallThrough()
    spyOn(model, '_emit').andCallFake ->

  it "Should set log entries", ->
    logData = ['first entry', 'second entry', 'third entry']

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual(logData)

  it "Should remove lines when max lines reached", ->
    logData = ['first entry', 'second entry', 'third entry', 'fourth entry']

    model.__set__ 'model.linesMax', 2

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual([logData[2], logData[3]])

  it "Should replace existing property if it is no array", ->
    model.__set__ '_store', {"log": {"1": "a line"}}

    logData = ['first entry', 'second entry', 'third entry']

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual(logData)

  it "Should fail when no property given", ->
    logData = ['first entry', 'second entry', 'third entry']

    model.log '', logData[0]
    model.log null, logData[1]

    expect(model.__get__('_store').log).toBeUndefined()

  it "Should log empty line", ->
    logData = ['first entry', '', null, false]

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual(logData)

  it "Should log empty line on undefined", ->
    logData = ['first entry', undefined]
    expected = ['first entry', null]

    for line in logData
      model.log 'log', line

    expect(model.__get__('_store').log).toEqual(expected)

  it "Should call emit", ->
    model.log 'log', 'test'

    expect(model._emit).toHaveBeenCalledWith('log', ['test'])

  it "Should call set one time when creating new log Array", ->
    logData = ['first entry', 'second entry', 'third entry']

    for line in logData
      model.log 'log', line

    expect(model.set.callCount).toBe(1)

  it "Should call emit without referenced log entries", ->
    model.__set__ '_store',
      log: [{"text": 'some content'}]

    model.log 'log', {"text": 'more content'}

    expect(model._emit.argsForCall[0][1]).toNotBe(model.__get__('_store').log)

describe 'set', ->

  beforeEach ->
    setup()
    spyOn(model, '_emit').andCallFake ->
    spyOn(model, '_isSame').andCallThrough()

  it "Should set string", ->
    val = 'new value'

    model.set 'new', val
    expect(model.__get__('_store').new).toBe(val)

  it "Should set boolean", ->
    model.set 'newFalse', false
    model.set 'newTrue', true

    expect(model.__get__('_store').newFalse).toBe(false)
    expect(model.__get__('_store').newTrue).toBe(true)

  it "Should set null", ->
    model.set 'new', null

    expect(model.__get__('_store').new).toBeNull()

  it "Should set null on undefined", ->
    model.set 'new'

    expect(model.__get__('_store').new).toBeNull()

  it "Should set object", ->
    val = {"k1": "v1", "k2": "v2"}

    model.set 'newObj', val
    expect(model.__get__('_store').newObj).toEqual(val)

  it "Should set array", ->
    val = ["v1", "v2"]

    model.set 'newAr', val
    expect(model.__get__('_store').newAr).toEqual(val)

  it "Should overwrite existing property", ->
    val = 'new value'

    model.set 'string', "first"
    model.set 'string', val

    expect(model.__get__('_store').string).toBe(val)

  it "Should call emit", ->
    model.set 'new', 'test'

    expect(model._emit).toHaveBeenCalledWith('new', 'test')

  it "Should not call emit", ->
    model.set

    model._isSame.andCallFake -> true
    model.set 'string', 'test uniqueness'

    expect(model._emit.wasCalled).toBeFalsy()

  it "Should not call isSame", ->
    model.uniqueness = true
    model.set 'new', 'test', false

    model.uniqueness = false
    model.set 'new', 'test2'

    expect(model._isSame.wasCalled).toBeFalsy()

  it "Should call isSame", ->
    model.uniqueness = false
    model.set 'new', 'test', true

    model.uniqueness = true
    model.set 'new', 'test2'

    expect(model._isSame.callCount).toBe(2)

  it "Should fail when no property given", ->
    expect(model.set '', 'something').toBeFalsy()
    expect(model.set null, 'something').toBeFalsy()

  it "Should set non referenced object", ->
    objectData = cloneObject data.object

    model.set 'obj', objectData
    objectData.ref = 'new reference'

    expect(model.__get__('_store').obj).toNotBe(objectData)


describe 'setChildProperty', ->

  beforeEach ->
    setup()
    spyOn(model, 'set').andCallThrough()
    spyOn(model, '_isSame').andCallThrough()
    spyOn(model, '_emit').andCallFake ->

  it "Should set string", ->
    val = 'new value'

    model.setChildProperty 'new', 'prop', val

    expect(model.__get__('_store').new.prop).toBe(val)

  it "Should set boolean", ->
    model.setChildProperty 'obj', 'false', false
    model.setChildProperty 'obj', 'true', true

    expect(model.__get__('_store').obj.false).toBe(false)
    expect(model.__get__('_store').obj.true).toBe(true)

  it "Should set null", ->
    model.setChildProperty 'obj', 'prop', null

    expect(model.__get__('_store').obj.prop).toBeNull()

  it "Should set null on undefined", ->
    model.setChildProperty 'obj', 'prop'

    expect(model.__get__('_store').obj.prop).toBeNull()

  it "Should set object", ->
    val = {"k1": "v1", "k2": "v2"}

    model.setChildProperty 'obj', 'prop', val
    expect(model.__get__('_store').obj.prop).toEqual(val)

  it "Should set array", ->
    val = ["v1", "v2"]

    model.setChildProperty 'obj', 'prop', val
    expect(model.__get__('_store').obj.prop).toEqual(val)

  it "Should overwrite existing property", ->
    val = 'new value'

    model.setChildProperty 'obj', 'prop', "first"
    model.setChildProperty 'obj', 'prop', val

    expect(model.__get__('_store').obj.prop).toBe(val)

  it "Should fail when no property or childname given", ->
    expect(model.setChildProperty '', 'something', 'something').toBeFalsy()
    expect(model.setChildProperty null, 'something', 'something').toBeFalsy()

    expect(model.setChildProperty 'object', '', 'something').toBeFalsy()
    expect(model.setChildProperty 'object', null, 'something').toBeFalsy()

  it "should fail when property is not an object", ->
    expect(model.setChildProperty 'string', 'something', 'something').toBeFalsy()
    expect(model.setChildProperty('array', 'new', 'something')).toBeFalsy()

  it "Should not call isSame", ->
    model.uniqueness = true
    model.setChildProperty 'object', 'test', 'val', false

    model.uniqueness = false
    model.setChildProperty 'object', 'test', 'val2', false

    expect(model._isSame.wasCalled).toBeFalsy()

  it "Should call isSame", ->
    model.uniqueness = false
    model.setChildProperty 'object', 'test', 'val', true

    model.uniqueness = true
    model.setChildProperty 'object', 'test', 'val2', true

    expect(model._isSame.callCount).toBe(2)

  it "Should set non referenced object", ->
    objectData = cloneObject data.object

    model.setChildProperty 'object', 'prop', objectData
    objectData.ref = 'new reference'

    expect(model.__get__('_store').object.prop).toNotBe(objectData)


describe 'getStream', ->

  beforeEach -> setup()

  it "should return observable", ->
    stream= model.getStream()

    expect(stream).toEqual(jasmine.any(Object))
    expect(stream.onValue).toEqual(jasmine.any(Function))
    expect(stream.onError).toEqual(jasmine.any(Function))
    expect(stream.onEnd).toEqual(jasmine.any(Function))

  it "should trigger on value event", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.getStream().onValue onV

    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

    model.set 'testOnValue', 'testing'

  it "should trigger event with setChildProperty", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.getStream().onValue onV

    model.setChildProperty 'newObject', 'testOnValue', 'test'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "should trigger event when same object and false unique flag", (done) ->
    _data = {key: 'val', key2: 'val2'}
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.getStream()
    .onValue onV

    model.set 'same', _data
    model.set 'same', _data, false

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 0

  it "should trigger event in deep object", (done) ->
    _data = {key: 'val', key2: 'val2'}
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.getStream()
    .onValue onV

    model.set 'notSame', _data
    _data.key = 'v3'
    model.set 'notSame', _data

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 0

  it "should not trigger event when setting undefined on non existing property", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.getStream()
    .onValue onV

    model.set 'same'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "should trigger event after setting undefined on existing property", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.getStream()
    .onValue onV

    model.set 'same'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "event value should contain property name, value", (done) ->
    model.getStream()
    .onValue (val) ->
      expect(val.hasOwnProperty("name")).toBeTruthy()
      expect(val.hasOwnProperty("value")).toBeTruthy()
      done()

    model.set 'testOnValue', 'testing'

  it "should return correct property", (done) ->
    name = 'testOnValue'
    value = 'testing'

    model.getStream()
    .onValue (val) ->
      expect(val.name).toEqual(name)
      expect(val.value).toEqual(value)
      done()

    model.set name, value

  it "should listen on all properties", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.getStream().onValue onV

    model.set 'testOnValue', 'testing'
    model.set 'totallyDifferentProperty', 'more testing'

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 0

  it "should trigger event from log", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.getStream()
    .onValue onV

    model.log 'newLog', 'first line'

    setTimeout ->
      model.log 'newLog', 'second line'
    , 10

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 100

# stream should react exactly like getStream with the exception that
# this stream only reacts to the given property
describe 'fromProperty', ->

  beforeEach -> setup()

  it "should return observable", ->
    stream=model.fromProperty('testOnValue')

    expect(stream).toEqual(jasmine.any(Object))
    expect(stream.onValue).toEqual(jasmine.any(Function))
    expect(stream.onError).toEqual(jasmine.any(Function))
    expect(stream.onEnd).toEqual(jasmine.any(Function))

  it "should trigger event", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.fromProperty('testOnValue').onValue onV

    model.set 'testOnValue', 'testing'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "should not trigger event on other properties", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.fromProperty('testOnValue').onValue onV

    model.set 'totallyDifferentProperty', 'test'
    setTimeout ->
      expect(onV.callCount).toBe(0)
      done()
    , 0

# stream should react exactly like getStream with the exception that
# this stream only reacts to the matching properties
describe 'fromRegex', ->

  beforeEach -> setup()

  it "should return observable", ->
    stream=model.fromRegex(/^regexp/)

    expect(stream).toEqual(jasmine.any(Object))
    expect(stream.onValue).toEqual(jasmine.any(Function))
    expect(stream.onError).toEqual(jasmine.any(Function))
    expect(stream.onEnd).toEqual(jasmine.any(Function))

  it "should trigger events", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.fromRegex(/^regexp/).onValue onV

    model.set 'regexp_1234', 'test regex'
    model.set 'regexp_23456', ['test more regex']

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 0

  it "should not trigger event on other properties", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.fromRegex(/^regexp/).onValue onV

    model.set 'nonregexp_1234', 'test regex'
    model.set 'nonregexp_23456', ['test more regex']
    setTimeout ->
      expect(onV.callCount).toBe(0)
      done()
    , 0