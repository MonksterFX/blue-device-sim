// you can use types, encoder and decoder

// type hints for the read function
readTypes.in = [];
readTypes.out = [types.String()];

function read(appStartTime, subscriptionTime) {
    const value = 'The time is: ' + new Date().toISOString();
    return encoder.encode(value, readTypes.out);
}

// type hints for the write function
writeTypes.in = [types.String()];
writeTypes.out = [];

function write(appStartTime, subscriptionTime, _value) {
    const value = decoder.decode(_value, writeTypes.in);
    console.log('Write value:', value);
    return true
}
