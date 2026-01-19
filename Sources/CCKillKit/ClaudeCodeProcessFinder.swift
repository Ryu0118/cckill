import Foundation
import Subprocess

/// Claude Code CLIプロセスを検出するクラス
public struct ClaudeCodeProcessFinder: Sendable {
    public init() {}

    /// Claude Code CLIプロセスを検出
    ///
    /// 識別条件:
    /// 1. プロセス名(comm)が `claude` である
    /// 2. コマンドライン引数に `/Applications/Claude.app` を含まない
    /// 3. コマンドライン引数が `claude` で始まる
    public func findProcesses() async throws -> [ClaudeCodeProcess] {
        let output = try await runPsCommand()
        return parseOutput(output)
    }

    /// psコマンドを実行
    private func runPsCommand() async throws -> String {
        let result = try await Subprocess.run(
            .path("/bin/ps"),
            arguments: ["-eo", "pid,comm,args,pcpu,pmem"],
            output: .string(limit: 1024 * 1024)  // 1MB limit
        )

        guard result.terminationStatus.isSuccess else {
            throw CCKillError.processListFailed("ps command failed with exit status: \(result.terminationStatus)")
        }

        guard let output = result.standardOutput else {
            throw CCKillError.parseError("Failed to decode ps output")
        }

        return output
    }

    /// psコマンドの出力をパース
    private func parseOutput(_ output: String) -> [ClaudeCodeProcess] {
        var processes: [ClaudeCodeProcess] = []
        let lines = output.components(separatedBy: "\n")

        // ヘッダー行をスキップ
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if let process = parseLine(trimmed) {
                processes.append(process)
            }
        }

        return processes
    }

    /// 1行をパースしてClaudeCodeProcessを返す（条件に合致しない場合はnil）
    private func parseLine(_ line: String) -> ClaudeCodeProcess? {
        // ps -eo pid,comm,args,pcpu,pmem の出力形式:
        // PID COMM ARGS %CPU %MEM
        // 数値は右寄せ、文字列は左寄せ

        let components = line.split(separator: " ", omittingEmptySubsequences: true)
        guard components.count >= 5 else { return nil }

        // PID
        guard let pid = Int32(components[0]) else { return nil }

        // COMM (プロセス名)
        let comm = String(components[1])

        // 条件1: プロセス名が claude であること
        guard comm == "claude" else { return nil }

        // 最後の2つは %CPU と %MEM
        guard let memUsage = Double(components[components.count - 1]),
              let cpuUsage = Double(components[components.count - 2]) else { return nil }

        // ARGS (コマンドライン引数) - COMMの後から%CPUの前まで
        let argsComponents = components[2..<(components.count - 2)]
        let args = argsComponents.joined(separator: " ")

        // 条件2: /Applications/Claude.app を含まないこと
        guard !args.contains("/Applications/Claude.app") else { return nil }

        // 条件3: コマンドが claude で始まること
        guard args.hasPrefix("claude") else { return nil }

        return ClaudeCodeProcess(
            pid: pid,
            command: args,
            cpuUsage: cpuUsage,
            memoryUsage: memUsage
        )
    }
}
