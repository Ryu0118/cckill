import Foundation

/// プロセスkillの結果
public struct KillResult: Sendable {
    /// 対象プロセスのPID
    public let pid: pid_t

    /// 成功したかどうか
    public let success: Bool

    /// エラーメッセージ（失敗時）
    public let errorMessage: String?

    public init(pid: pid_t, success: Bool, errorMessage: String? = nil) {
        self.pid = pid
        self.success = success
        self.errorMessage = errorMessage
    }

    /// 成功結果を作成
    public static func success(pid: pid_t) -> KillResult {
        KillResult(pid: pid, success: true)
    }

    /// 失敗結果を作成
    public static func failure(pid: pid_t, error: String) -> KillResult {
        KillResult(pid: pid, success: false, errorMessage: error)
    }
}

extension KillResult: CustomStringConvertible {
    public var description: String {
        if success {
            return "[OK] PID \(pid)"
        } else {
            return "[FAILED] PID \(pid): \(errorMessage ?? "Unknown error")"
        }
    }
}
