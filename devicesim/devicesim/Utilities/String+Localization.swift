import Foundation

extension String {
    /// Returns the localized string from Localizable.strings
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Returns the localized string with format arguments
    /// - Parameter arguments: The arguments to insert into the format string
    func localized(_ arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}

// MARK: - Localization Keys
extension String {
    enum Common {
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let done = "common.done"
        static let error = "common.error"
        static let success = "common.success"
    }
    
    enum Bluetooth {
        static let scanning = "bluetooth.scanning"
        static let connect = "bluetooth.connect"
        static let disconnect = "bluetooth.disconnect"
        static let connected = "bluetooth.connected"
        static let disconnected = "bluetooth.disconnected"
        
        enum Error {
            static let connection = "bluetooth.error.connection"
            static let timeout = "bluetooth.error.timeout"
            static let unauthorized = "bluetooth.error.unauthorized"
        }
    }
    
    enum Settings {
        static let title = "settings.title"
        static let bluetooth = "settings.bluetooth"
        static let device = "settings.device"
        static let advanced = "settings.advanced"
        static let about = "settings.about"
        static let version = "settings.version"
    }
    
    enum Error {
        static let general = "error.general"
        static let tryAgain = "error.try_again"
        static let noConnection = "error.no_connection"
    }
} 