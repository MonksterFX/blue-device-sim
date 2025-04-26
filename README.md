# Bluetooth Device Simulator

A macOS application that simulates a Bluetooth Low Energy (BLE) peripheral device. This application allows iOS devices to connect and interact with it.

## Features

- Simulates a BLE peripheral device
- Advertises custom services and characteristics
- Allows iOS devices to connect and read/write data
- Simple user interface to control the peripheral state

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

## License

MIT License 

## AI Usage
This repro is currently heavily developed with Cursor AI. Please not that there will be major structural changes at all times until rules, process and code style is etablished.

## JavaScript Function Example

When using the JavaScript function editor, you must define both a `read` and a `write` function. These functions will be called by the simulator with the appropriate arguments.

Example:

```javascript
/**
 * @param {number} appStartTime - The time (in ms since epoch) when the app started
 * @param {number} subscriptionTime - The time (in ms since epoch) when the subscription started
 * @returns {string|number|object} The value to return to the client
 */
function read(appStartTime, subscriptionTime) {
    // Return a string, number, or object
    return 'Read value: ' + new Date().toISOString();
}

/**
 * @param {number} appStartTime - The time (in ms since epoch) when the app started
 * @param {number} subscriptionTime - The time (in ms since epoch) when the subscription started
 * @param {string} value - The value written by the client
 * @returns {string|number|object|boolean} The result of the write operation
 */
function write(appStartTime, subscriptionTime, value) {
    // Log the value and return a result
    console.log('Write value:', value);
    return true;
}
```

- `appStartTime`: The time (in ms since epoch) when the app started
- `subscriptionTime`: The time (in ms since epoch) when the subscription started
- `value`: The value written by the client (for write only)

Both functions must be present in the editor for correct operation.