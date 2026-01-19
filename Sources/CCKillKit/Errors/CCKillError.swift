import Foundation

/// Errors that can occur in CCKill
public enum CCKillError: Error, LocalizedError, Sendable {
    /// Failed to execute ps command
    case processListFailed(String)

    /// Failed to parse ps command output
    case parseError(String)

    /// Failed to kill process
    case killFailed(pid: pid_t, reason: String)

    /// Permission denied
    case permissionDenied(pid: pid_t)

    public var errorDescription: String? {
        switch self {
        case .processListFailed(let message):
            return "Failed to list processes: \(message)"
        case .parseError(let message):
            return "Failed to parse process list: \(message)"
        case .killFailed(let pid, let reason):
            return "Failed to kill process \(pid): \(reason)"
        case .permissionDenied(let pid):
            return "Permission denied to kill process \(pid)"
        }
    }
}
