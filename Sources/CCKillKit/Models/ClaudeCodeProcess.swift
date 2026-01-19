import Foundation

/// A model representing a Claude Code CLI process
public struct ClaudeCodeProcess: Sendable {
    /// Process ID
    public let pid: pid_t

    /// Command line arguments
    public let command: String

    /// CPU usage (%)
    public let cpuUsage: Double

    /// Memory usage (%)
    public let memoryUsage: Double

    public init(pid: pid_t, command: String, cpuUsage: Double, memoryUsage: Double) {
        self.pid = pid
        self.command = command
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
    }
}

extension ClaudeCodeProcess: CustomStringConvertible {
    public var description: String {
        "PID \(pid): \(command) (CPU: \(String(format: "%.1f", cpuUsage))%, MEM: \(String(format: "%.1f", memoryUsage))%)"
    }
}
