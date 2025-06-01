import Foundation
import JavaScriptCore

typealias LogStream = (String) -> Void

struct JavaScriptEngine {
    // single instance of the JavaScript engine, context is keeped alive
    private let context: JSContext

    private(set) var canRead: Bool = false
    private(set) var canWrite: Bool = false

    private func loadJavaScriptFile(resourceName: String, fileExtension: String = "js") -> Bool {
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: fileExtension) else {
            print("Error: Could not find \(resourceName).\(fileExtension) script")
            return false
        }
        
        do {
            let script = try String(contentsOf: fileURL, encoding: .utf8)
            context.evaluateScript(script)
            return true
        } catch {
            print("Error loading script: \(error)")
            return false
        }
    }

    init?(jsFunctionsCode: String, logStream: LogStream? = nil) {
        self.context = JSContext()!
        
        // add error handler
        context.exceptionHandler = { _, exception in
            if let exc = exception {
                logStream?("JS Error: \(exc.toString() ?? "Unknown error")")
            }
        }
        
        let consoleLog: @convention(block) (String) -> Void = { message in
            logStream?(message) 
        }

        // add consoleLog to the context
        context.setObject(consoleLog, forKeyedSubscript: "consoleLog" as NSString) 

        // create a console object with a log method that logs to the log stream and accepts multiple arguments
        context.evaluateScript("const console = {log: (...args)=>{ consoleLog(args.map(arg=>arg.toString()).join(' ')); }}")
        
        // add polyfill, typed support and other scripts to the context
        guard loadJavaScriptFile(resourceName: "textencoder") else { return nil }
        guard loadJavaScriptFile(resourceName: "tx-typed.min") else { return nil }
        guard loadJavaScriptFile(resourceName: "context") else { return nil }

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
        
        // print globals
        // let global = context.globalObject
        // print(global?.toDictionary() ?? [:])
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

    func runRead(appStartTime: Date = Date(), subscriptionTime: Date = Date()) -> (Data) {
        let _appStartTime = appStartTime.timeIntervalSince1970 * 1000
        let _appSubscriptionTime = subscriptionTime.timeIntervalSince1970 * 1000
        
        guard let result: JSValue = (self.context.evaluateScript("read(\(_appStartTime),\(_appSubscriptionTime))")) else {
            return Data()
        }
        return jsArrayBufferToData(result) ?? Data()
    }

    func runWrite(appStartTime: Date = Date(), subscriptionTime: Date = Date(), value: Data) -> (Data) {
        let _appStartTime = appStartTime.timeIntervalSince1970 * 1000
        let _appSubscriptionTime = subscriptionTime.timeIntervalSince1970 * 1000
        let _data = Array(value)
        
        // TODO: thats dirty! 
        guard let result: JSValue = (self.context.evaluateScript("write(\(_appStartTime),\(_appSubscriptionTime),new Uint8Array(\(_data)));")) else {
            return Data()
        }
        return jsArrayBufferToData(result) ?? Data()
    }

    func getTypeHint(key: TypeHintKey) -> String {
        let result = self.context.evaluateScript("generateTypeHints(\(key.rawValue))")
        return result?.toString() ?? "No type hint defined"
    }
} 
