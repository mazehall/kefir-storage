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
  model._initStream()


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


describe '_initStream', ->

  _observe = null
  _observeSpy = null

  afterEach -> Object.observe = _observe if _observe

  beforeEach ->
    model = rewire "../src/ks.coffee"

    _observe = Object.observe
    _observeSpy = jasmine.createSpy('Object.observe').andCallFake (property, callback) ->
      callback [{name: "test"}]
    Object.observe = _observeSpy

    model.__set__ '_r',
      stream: jasmine.createSpy('kefir.stream').andCallFake (x) -> x('emitter')

    spyOn(model, '_emitProperty').andCallFake ->

  it 'should call _emitProperty', ->
    model._initStream()

    expect(model._emitProperty).toHaveBeenCalledWith('emitter', {name: "test"})

  it 'should call _r.stream', ->
    model._initStream()

    expect(model.__get__('_r').stream).toHaveBeenCalledWith(jasmine.any(Function))

  it 'should call Object.observe', ->
    model._initStream()

    expect(_observeSpy).toHaveBeenCalledWith([], jasmine.any(Function))

  it 'should call Object.observe with current store', ->
    expected = cloneObject data

    model.__set__ '_store', expected
    model._initStream()

    expect(_observeSpy).toHaveBeenCalledWith(expected, jasmine.any(Function))


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


describe '_isUnique', ->

  beforeEach -> setup()

  it "Should return true so unique", ->
    expect(model._isUnique('null', 'null')).toBeTruthy()
    expect(model._isUnique('bTrue', false)).toBeTruthy()
    expect(model._isUnique('string', "you are string")).toBeTruthy()
    expect(model._isUnique('object', ["test", "test2"])).toBeTruthy()
    expect(model._isUnique('array', {some: "more"})).toBeTruthy()

  it "Should return false so duplicate", ->
    for key, value of data
      expect(model._isUnique(key, value)).toBeFalsy()


describe '_emitProperty', ->

  _emitter = null

  beforeEach ->
    setup()
    _emitter =
      emit: jasmine.createSpy('emitter.emit').andCallFake ->

  it "should emit property", ->
    key = 'string'
    expected =
      name: key,
      value: data[key]
      oldVal: undefined

    model._emitProperty _emitter,
      type: 'add',
      object: cloneObject model.__get__('_store')
      name: key

    expect(_emitter.emit).toHaveBeenCalledWith(expected)

  it "should also emit old value", ->
    key = 'string'
    expected =
      name: key,
      value: data[key]
      oldValue: 'very old'

    model._emitProperty _emitter,
      type: 'add',
      object: cloneObject model.__get__('_store')
      oldValue: 'very old'
      name: key

    expect(_emitter.emit).toHaveBeenCalledWith(expected)


describe '_set', ->

  beforeEach ->
    setup()
    spyOn(model, '_isUnique').andCallThrough()

  it "Should set string", ->
    val = 'new value'

    model._set 'new', val
    expect(model.__get__('_store').new).toBe(val)

  it "Should set boolean", ->
    model._set 'newFalse', false
    model._set 'newTrue', true

    expect(model.__get__('_store').newFalse).toBe(false)
    expect(model.__get__('_store').newTrue).toBe(true)

  it "Should set null", ->
    model._set 'new', null

    expect(model.__get__('_store').new).toBeNull()

  it "Should set undefined", ->
    model._set 'new'

    expect(model.__get__('_store').new).toBeUndefined()

  it "Should set object", ->
    val = {"k1": "v1", "k2": "v2"}

    model._set 'newObj', val
    expect(model.__get__('_store').newObj).toEqual(val)

  it "Should set array", ->
    val = ["v1", "v2"]

    model._set 'newAr', val
    expect(model.__get__('_store').newAr).toEqual(val)

  it "Should overwrite existing property", ->
    val = 'new value'

    model._set 'string', "first"
    model._set 'string', val

    expect(model.__get__('_store').string).toBe(val)

  it "Should not call _isUnique", ->
    model.uniqueness = true
    model._set 'new', 'test', false

    model.uniqueness = false
    model._set 'new', 'test2'

    expect(model._isUnique.wasCalled).toBeFalsy()

  it "Should call _isUnique", ->
    model.uniqueness = false
    model._set 'new', 'test', true

    model.uniqueness = true
    model._set 'new', 'test2'

    expect(model._isUnique.callCount).toBe(2)


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


describe 'log', ->

  beforeEach -> setup()

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


describe 'set', ->

  beforeEach ->
    setup()
    spyOn(model, '_set').andCallFake ->

  it "Should call _set", ->
    model.set 'new', 'something'

    expect(model._set).toHaveBeenCalledWith('new', 'something', undefined)

  it "Should call _set with uniqueness flag", ->
    model.set 'new', 'something', true

    expect(model._set).toHaveBeenCalledWith('new', 'something', true)

  it "Should set null when no value was given", ->
    model.set 'new'

    expect(model._set).toHaveBeenCalledWith('new', null, undefined)

  it "Should fail when no property given", ->
    expect(model.set '', 'something').toBeFalsy()
    expect(model.set null, 'something').toBeFalsy()


describe 'setChildProperty', ->

  beforeEach ->
    setup()
    spyOn(model, '_set').andCallFake ->

  it "Should call _set", ->
    model.setChildProperty 'again', 'something', 'new'

    expect(model._set).toHaveBeenCalledWith('again', {something: 'new'}, undefined)

  it "Should call _set with uniqueness flag", ->
    model.setChildProperty 'again', 'something', 'new', true

    expect(model._set).toHaveBeenCalledWith('again', {something: 'new'}, true)

  it "Should set null when no value was given", ->
    model.setChildProperty 'again', 'something'

    expect(model._set).toHaveBeenCalledWith('again', {something: null}, undefined)

  it "Should fail when no property or childname given", ->
    expect(model.setChildProperty '', 'something', 'something').toBeFalsy()
    expect(model.setChildProperty null, 'something', 'something').toBeFalsy()

    expect(model.setChildProperty 'object', '', 'something').toBeFalsy()
    expect(model.setChildProperty 'object', null, 'something').toBeFalsy()

  it "should fail when property is not an object", ->
    expect(model.setChildProperty 'string', 'something', 'something').toBeFalsy()
    expect(model.setChildProperty('array', 'new', 'something')).toBeFalsy()


describe 'stream', ->

  beforeEach -> setup()

  it "should return observable", ->
    stream= model.stream()

    expect(stream).toEqual(jasmine.any(Object))
    expect(stream.onValue).toEqual(jasmine.any(Function))
    expect(stream.onError).toEqual(jasmine.any(Function))
    expect(stream.onEnd).toEqual(jasmine.any(Function))

  it "should trigger on value event", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.stream().onValue onV

    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

    model.set 'testOnValue', 'testing'

  it "should trigger event with setChildProperty", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.stream().onValue onV

    model.setChildProperty 'newObject', 'testOnValue', 'test'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "should trigger event when same object and false unique flag", (done) ->
    _data = {key: 'val', key2: 'val2'}
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.stream()
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

    model.stream()
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

    model.stream()
    .onValue onV

    model.set 'same'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "should trigger event after setting undefined on existing property", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.stream()
    .onValue onV

    model.set 'same'
    setTimeout ->
      expect(onV.callCount).toBe(1)
      done()
    , 0

  it "event value should contain property name, oldValue, value", (done) ->
    model.stream()
    .onValue (val) ->
      expect(val.hasOwnProperty("name")).toBeTruthy()
      expect(val.hasOwnProperty("oldValue")).toBeTruthy()
      expect(val.hasOwnProperty("value")).toBeTruthy()
      done()

    model.set 'testOnValue', 'testing'

  it "should return correct property", (done) ->
    name = 'testOnValue'
    value = 'testing'

    model.stream()
    .onValue (val) ->
      expect(val.name).toEqual(name)
      expect(val.value).toEqual(value)
      expect(val.oldValue).toBeUndefined()
      done()

    model.set name, value

  it "should return correct defined old value", (done) ->
    val1 = 'testing'
    val2 = 'more testing'

    model.stream()
    .onValue (val) ->
      return false if val.value != val2
      expect(val.oldValue).toEqual(val1)
      done()
    .onValue (val) ->
      setTimeout ->
        model.set 'testOnValue', val2 if val.value == val1
      , 1

    model.set 'testOnValue', val1

  it "should listen on all properties", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.stream().onValue onV

    model.set 'testOnValue', 'testing'
    model.set 'totallyDifferentProperty', 'more testing'

    setTimeout ->
      expect(onV.callCount).toBe(2)
      done()
    , 0

  it "should trigger event from log", (done) ->
    onV = jasmine.createSpy('onValue').andCallFake ->

    model.stream()
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