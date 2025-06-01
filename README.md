# Bluetooth Device Simulator

A macOS application that simulates a Bluetooth Low Energy (BLE) peripheral device. This application allows iOS devices to connect and interact with it.

## Features

- Simulates a BLE peripheral device
- Advertises custom services and characteristics
- Allows iOS devices to connect and read/write data
- Advanced JavaScript function support for dynamic responses
- Preset management for JavaScript functions
- Real-time testing of JavaScript functions
- Profile management for device settings
- Detailed logging and debugging capabilities

## Requirements

- macOS 11.0 or later
- Xcode 13.0 or later
- Swift 5.5 or later

## Setup

1. Clone this repository
2. Open the project in Xcode
3. Build and run the application
4. Use the iOS app to connect to this simulated device

## Usage

1. Launch the application
2. Click "Start Advertising" to begin broadcasting as a BLE peripheral
3. Use your iOS device to scan for and connect to this device
4. Interact with the simulated services and characteristics

### JavaScript Functions

The simulator supports dynamic responses through JavaScript functions. You can:
- Create and manage function presets
- Test functions in real-time
- Use type hints for better function development
- Support for read, write, and notify operations

### Profiles

- Save and load different device configurations
- Customize device name, service UUID, and characteristic UUID
- Manage manufacturer data and RSSI settings
- Auto-response capabilities

## License

MIT License 

## AI Usage
This repo is currently heavily developed with Cursor AI. Please note that there will be major structural changes at all times until rules, process and code style is established.

## JavaScript Function Example

When using the JavaScript function editor, you must define both a `read` and a `write` function. These functions will be called by the simulator with the appropriate arguments.

Example:

```javascript
// type hints for the read function
readTypes = [types.String()];

function read() {
    const value = 'The time is: ' + new Date().toISOString();
    return encoder.encode(value, readTypes);
}

// type hints for the write function
writeTypes = [types.Double];

function write(value) {
    const parsed = decoder.decode(value, writeTypes);
    console.log('Parsed value:', parsed);
    return true
}
```

### Type Support

The simulator supports various data types for JavaScript functions:
- String
- Number
- Buffer
- Custom objects

### Testing

The simulator includes a built-in testing interface that allows you to:
- Test read and write operations
- View real-time function output
- Debug function behavior
- Validate type conversions