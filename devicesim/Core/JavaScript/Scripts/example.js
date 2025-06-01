// you can use types, encoder and decoder

// type hints for the read function
readTypes = [types.String()];

function read() {
    const value = 'The time is: ' + new Date().toISOString();
    return encoder.encode(value, readTypes);
}

// type hints for the write function
writeTypes = [types.String()];

function write(value) {
    const parsed = decoder.decode(value, writeTypes);
    console.log('Parsed value:', parsed);
    return true
}
