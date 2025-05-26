import Foundation
import JavaScriptCore

typealias LogStream = (String) -> Void

struct JavaScriptEngine {
    // single instance of the JavaScript engine, context is keeped alive
    private let context: JSContext

    private(set) var canRead: Bool = false
    private(set) var canWrite: Bool = false

    init?(jsFunctionsCode: String, logStream: LogStream? = nil) {
        self.context = JSContext()!
        
        let consoleLog: @convention(block) (String) -> Void = { message in
            logStream?(message) 
        }

        context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString) 

        // create a console object with a log method that logs to the log stream and accepts multiple arguments
        context.evaluateScript("const console = {log: (...args)=>{ consoleLog(args.map(arg=>arg.toString()).join(' ')); }}")
        
        // add error handler
        context.exceptionHandler = { _, exception in
            if let exc = exception {
                print("JS Error: \(exc.toString() ?? "Unknown error")")
            }
        }

        // load the JavaScript code
        if !loadAndValidate(jsFunctionsCode: jsFunctionsCode) {
            print("JS Error: Invalid JavaScript code")
            return nil
        }

        // check if the read function is defined
        if !supportsRead() {
            canRead = false
            print("No read function defined")
        } else {
            canRead = true
        }

        // check if the write function is defined
        if !supportsWrite() {   
            canWrite = false
            print(" No write function defined")
        } else {
            canWrite = true
        }
    }
    
    // TODO: decide which datatypes to support
    // parse the return value of the JavaScript function
    private func parseReturnValue(result: JSValue) -> String {
        var resultString = ""

        if result.isString {
            resultString = result.toString() ?? ""
        } else if result.isNumber {
            resultString = "\(result.toNumber() ?? 0)"
        } else if result.isObject {
            let stringifyCall = "JSON.stringify(\(result))"
            let jsonResult = self.context.evaluateScript(stringifyCall)
            resultString = jsonResult?.toString() ?? "[object]"
        }
        return resultString
    }

    // check if the JavaScript code is valid
    func loadAndValidate(jsFunctionsCode: String) -> Bool {
        let result = self.context.evaluateScript(jsFunctionsCode)
        return result != nil
    }

    // checks if a read function is defined
    func supportsRead() -> Bool {
        let result = self.context.evaluateScript("read")
        return result != nil
    }
    
    // checks if a write function is defined
    func supportsWrite() -> Bool {          
        let result = self.context.evaluateScript("write")
        return result != nil
    }

    func runRead(appStartTime: Date = Date(), subscriptionTime: Date = Date()) -> (String) {
        guard let result = (self.context.evaluateScript("read(\(appStartTime.timeIntervalSince1970 * 1000), \(subscriptionTime.timeIntervalSince1970 * 1000))")) else { return "test" }
        return (parseReturnValue(result: result))
    }

    func runWrite(appStartTime: Date = Date(), subscriptionTime: Date = Date(), value: String) -> (String) {
        guard let result = (self.context.evaluateScript("write(\(appStartTime.timeIntervalSince1970 * 1000), \(subscriptionTime.timeIntervalSince1970 * 1000), '\(value)')")) else { return "test" }
        return (parseReturnValue(result: result))
    }
} 