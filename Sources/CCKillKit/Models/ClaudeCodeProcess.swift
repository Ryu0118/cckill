import Foundation

/// Claude Code CLIプロセスを表すモデル
public struct ClaudeCodeProcess: Sendable {
    /// プロセスID
    public let pid: pid_t

    /// コマンドライン引数
    public let command: String

    /// CPU使用率 (%)
    public let cpuUsage: Double

    /// メモリ使用率 (%)
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
