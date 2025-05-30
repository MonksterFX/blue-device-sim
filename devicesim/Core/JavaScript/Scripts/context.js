const {types, ArrayBufferEncoder, ArrayBufferDecoder, generateTypeHints} = typed;

// Create instances
const encoder = new ArrayBufferEncoder();
const decoder = new ArrayBufferDecoder();

// type hints for the read function
const readTypes = {
	"in": [],
	"out": []
}

// type hints for the write function
const writeTypes = {
	"in": [],
	"out": []
}