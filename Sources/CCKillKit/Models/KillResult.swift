import Foundation

/// Result of a process kill operation
public struct KillResult: Sendable {
    /// PID of the target process
    public let pid: pid_t

    /// Whether the operation was successful
    public let success: Bool

    /// Error message (on failure)
    public let errorMessage: String?

    public init(pid: pid_t, success: Bool, errorMessage: String? = nil) {
        self.pid = pid
        self.success = success
        self.errorMessage = errorMessage
    }

    /// Creates a success result
    public static func success(pid: pid_t) -> KillResult {
        KillResult(pid: pid, success: true)
    }

    /// Creates a failure result
    public static func failure(pid: pid_t, error: String) -> KillResult {
        KillResult(pid: pid, success: false, errorMessage: error)
    }
}

extension KillResult: CustomStringConvertible {
    public var description: String {
        if success {
            return "✅ PID \(pid)"
        } else {
            return "❌ PID \(pid): \(errorMessage ?? "Unknown error")"
        }
    }
}
