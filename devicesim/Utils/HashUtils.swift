import Foundation
import CryptoKit

enum HashUtils {
    /// Generates a SHA-256 hash from a string
    /// - Parameter string: The input string to hash
    /// - Returns: A hexadecimal string representation of the SHA-256 hash
    static func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
} 