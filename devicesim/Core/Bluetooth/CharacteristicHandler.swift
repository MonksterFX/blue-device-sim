import Foundation
import JavaScriptCore

/// Represents a handler for a characteristic that can execute JavaScript code
class CharacteristicHandler {
    enum OperationType: String {
        case read
        case notify
    }
    
    /// The JavaScript function to execute
    let jsFunction: String
    
    /// The notification interval in seconds (only used for notify characteristics)
    let notifyInterval: TimeInterval
    
    /// The UUID of the characteristic this handler is associated with
    let characteristicUUID: String
    
    /// The time when the application started
    private let appStartTime: Date
    
    /// The time when the first device subscribed to the characteristic
    private var firstSubscriptionTime: Date?
    
    /// JavaScript context for executing the function
    private let jsContext = JSContext()!
    
    /// Timer for sending notifications at intervals
    private var notificationTimer: Timer?
    
    init(characteristicUUID: String, jsFunction: String, notifyInterval: TimeInterval = 1.0) {
        self.characteristicUUID = characteristicUUID
        self.jsFunction = jsFunction
        self.notifyInterval = notifyInterval
        self.appStartTime = Date()
        
        setupJSContext()
    }
    
    /// Sets up the JavaScript context with necessary global values and functions
    private func setupJSContext() {
        // Add console.log support
        let consoleLog: @convention(block) (String) -> Void = { message in
            print("JS Console: \(message)")
        }
        jsContext.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString)
        jsContext.evaluateScript("console = { log: consoleLog }")
        
        // Handle JS exceptions
        jsContext.exceptionHandler = { context, exception in
            if let exc = exception {
                print("JS Error: \(exc.toString() ?? "Unknown error")")
            }
        }
        
        // Add the function to the context
        jsContext.evaluateScript("""
        function evaluateCharacteristicFunction(appStartTime, subscriptionTime, isRead) {
            \(jsFunction)
        }
        """)
    }
    
    /// Called when a device subscribes to this characteristic
    func handleSubscription() {
        if firstSubscriptionTime == nil {
            firstSubscriptionTime = Date()
        }
    }
    
    /// Evaluates the JavaScript function for a read request
    func handleReadRequest() -> Data? {
        return evaluateJS(operationType: .read)
    }
    
    /// Starts sending notifications at the specified interval
    func startNotifications(notificationHandler: @escaping (Data) -> Void) {
        handleSubscription()
        
        // Stop any existing timer
        stopNotifications()
        
        // Create new timer
        notificationTimer = Timer.scheduledTimer(withTimeInterval: notifyInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return } // Capture self weakly
            if let data = self.evaluateJS(operationType: .notify) {
                notificationHandler(data)
            }
        }
    }
    
    /// Stops sending notifications
    func stopNotifications() {
        notificationTimer?.invalidate()
        notificationTimer = nil
    }
    
    /// Evaluates the JavaScript function and returns the result as Data
    private func evaluateJS(operationType: OperationType) -> Data? {
        // Convert dates to milliseconds since epoch for JavaScript
        let appStartTimeMs = appStartTime.timeIntervalSince1970 * 1000
        let subscriptionTimeMs = (firstSubscriptionTime ?? Date()).timeIntervalSince1970 * 1000
        let isRead = operationType == .read
        
        // Call the function with the required parameters
        let jsCall = "evaluateCharacteristicFunction(\(appStartTimeMs), \(subscriptionTimeMs), \(isRead))"
        guard let result = jsContext.evaluateScript(jsCall) else {
            return nil
        }
        
        // Convert result to string then to data
        if result.isString {
            return result.toString()?.data(using: .utf8)
        } else if result.isNumber {
            let numberValue = result.toNumber()
            return "\(numberValue ?? 0)".data(using: .utf8)
        } else if result.isObject {
            // Try to stringify if it's an object
            // Note: We need to call the function again inside stringify to get the object result
            let stringifyCall = "JSON.stringify(evaluateCharacteristicFunction(\(appStartTimeMs), \(subscriptionTimeMs), \(isRead)))"
            let jsonResult = jsContext.evaluateScript(stringifyCall)
            return jsonResult?.toString()?.data(using: .utf8)
        } else if result.isUndefined || result.isNull {
             return nil // Return nil or empty data for undefined/null
        }
        
        // Fallback for other types (like boolean)
        return result.toString()?.data(using: .utf8)
    }
} 
