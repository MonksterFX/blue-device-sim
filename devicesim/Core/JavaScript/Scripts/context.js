const {types, ArrayBufferEncoder, ArrayBufferDecoder, generateTypeHints} = typed;

// Create instances
const encoder = new ArrayBufferEncoder();
const decoder = new ArrayBufferDecoder();

// type hints for the read function
let readTypes = [];
// type hints for the write function
let writeTypes = [];