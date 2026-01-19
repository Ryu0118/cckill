import Foundation

/// CCKillで発生するエラー
public enum CCKillError: Error, LocalizedError, Sendable {
    /// psコマンドの実行に失敗
    case processListFailed(String)

    /// psコマンドの出力パースに失敗
    case parseError(String)

    /// kill操作に失敗
    case killFailed(pid: pid_t, reason: String)

    /// 権限不足
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
