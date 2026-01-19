import Darwin
import Foundation

/// プロセスをkillするクラス
public struct ProcessKiller: Sendable {
    public init() {}

    /// 指定したプロセスをkill
    ///
    /// - Parameters:
    ///   - process: killするプロセス
    ///   - force: true の場合 SIGKILL、false の場合 SIGTERM を使用
    /// - Returns: kill結果
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

    /// 複数のプロセスをkill
    ///
    /// - Parameters:
    ///   - processes: killするプロセスのリスト
    ///   - force: true の場合 SIGKILL、false の場合 SIGTERM を使用
    /// - Returns: 各プロセスのkill結果
    public func killAll(processes: [ClaudeCodeProcess], force: Bool = false) -> [KillResult] {
        processes.map { kill(process: $0, force: force) }
    }
}
