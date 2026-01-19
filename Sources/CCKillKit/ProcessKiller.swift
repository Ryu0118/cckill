import Darwin
import Foundation

/// A struct for killing processes
public struct ProcessKiller: Sendable {
    public init() {}

    /// Kills the specified process
    ///
    /// - Parameters:
    ///   - process: The process to kill
    ///   - force: If true, uses SIGKILL; otherwise uses SIGTERM
    /// - Returns: The result of the kill operation
    public func kill(process: ClaudeCodeProcess, force: Bool = false) -> KillResult {
        let signal: Int32 = force ? SIGKILL : SIGTERM
        let result = Darwin.kill(process.pid, signal)

        if result == 0 {
            return .success(pid: process.pid)
        } else {
            let errorMessage = String(cString: strerror(errno))
            if errno == EPERM {
                return .failure(pid: process.pid, error: "Permission denied")
            }
            return .failure(pid: process.pid, error: errorMessage)
        }
    }

    /// Kills multiple processes
    ///
    /// - Parameters:
    ///   - processes: List of processes to kill
    ///   - force: If true, uses SIGKILL; otherwise uses SIGTERM
    /// - Returns: The result of each kill operation
    public func killAll(processes: [ClaudeCodeProcess], force: Bool = false) -> [KillResult] {
        processes.map { kill(process: $0, force: force) }
    }
}
