# Kefir-storage

Observe storage changes through kefir.


## Installation

````
$ [sudo] npm install --save kefir-storage
````
    
## Usage

```
var ks = require('kefir-storage');

// get stream which emits every change
ks.getStream()
.log();

// get kefir stream which emits only property changes
ks.fromProperty('test')
.onValue(function(property) {
  console.log('from property:', property.name, property.value);
});

// get kefir stream which emits only property changes
ks.fromRegex(/^regexp/)
.onValue(function(property) {
  console.log('from regex:', property.name, property.value);
});

ks.set('rnd', 'first');
// [pool] <value> { name: 'rnd', value: 'first' }

ks.set('test', 'second');
// [pool] <value> { name: 'test', value: 'second' }
// from property: test second

ks.set('regexp_12345', 'third');
// [pool] <value> { name: 'regexp_12345', value: 'third' }
// from regex: regexp_12345 third

ks.set('regexp_23456', 'fourth');
// [pool] <value> { name: 'regexp_23456', value: 'fourth' }
// from regex: regexp_23456 fourth
```

## API

### linesMax

(Default: 300) Determines how many log entries can be stored.

This value can be changed:

```ks.linesMax = 100```

### uniqueness

(Default: true) Determines the default uniqueness behavior.

If this value is true then all set and setChildProperty calls are checked if they would set same as the current value. If this is the case, then nothing will be emitted.

This value can be changed:

```ks.uniqueness = false```

model.linesMax = 300
model.uniqueness = true

### fromProperty(propertyName)

Returns kefir stream which emits only property changes.

### fromRegex(regexp)

Returns kefir stream which emits only properties that match the regular expression.

### get(propertyName)

Returns current property state.

### getStream()

Returns kefir stream which emits every change

### log(propertyName, value)

Adds a new line (Array entry) to the property. If the property is not an array it will be overwritten.

When the amount of entries passes the limit, then the last entry will be removed. 

### set(propertyName, value, unique)

Sets the value of a property.

The unique flag determines if the value will be emitted if it is the same as the current value.
 
### setChildProperty(propertyName, childName, value, unique)

Sets the property of an object.

The unique flag determines if the value will be emitted if it is the same as the current value.
