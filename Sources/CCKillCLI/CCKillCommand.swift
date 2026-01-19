import ArgumentParser
import CCKillKit
import Foundation

/// Claude Code CLIプロセスをkillするコマンド
public struct CCKillCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "cckill",
        abstract: "Kill Claude Code CLI processes (excluding Claude Desktop App)",
        version: "1.0.0"
    )

    @Flag(name: .shortAndLong, help: "List Claude Code processes without killing")
    var list: Bool = false

    @Flag(name: .shortAndLong, help: "Force kill using SIGKILL instead of SIGTERM")
    var force: Bool = false

    public init() {}

    public func run() async throws {
        let finder = ClaudeCodeProcessFinder()
        let processes: [ClaudeCodeProcess]

        do {
            processes = try await finder.findProcesses()
        } catch {
            printError("Error: \(error.localizedDescription)")
            throw ExitCode.failure
        }

        if processes.isEmpty {
            print("No Claude Code processes found.")
            return
        }

        // --list の場合はプロセス一覧を表示
        if list {
            printProcessList(processes)
            return
        }

        // プロセスをkill
        let killer = ProcessKiller()
        let results = killer.killAll(processes: processes, force: force)

        printResults(results, force: force)

        // 1つでも失敗があればエラー終了
        let hasFailure = results.contains { !$0.success }
        if hasFailure {
            throw ExitCode.failure
        }
    }

    /// プロセス一覧を表示
    private func printProcessList(_ processes: [ClaudeCodeProcess]) {
        print("Claude Code Processes:")
        for process in processes {
            print("  \(process)")
        }
    }

    /// kill結果を表示
    private func printResults(_ results: [KillResult], force: Bool) {
        let signalName = force ? "SIGKILL" : "SIGTERM"
        let successCount = results.filter(\.success).count
        let totalCount = results.count

        print("Killed \(successCount)/\(totalCount) Claude Code processes (\(signalName)):")
        for result in results {
            print("  \(result)")
        }
    }

    /// エラーメッセージを標準エラー出力に出力
    private func printError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
