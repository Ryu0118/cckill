import ArgumentParser
import CCKillKit
import Foundation

/// Command to kill Claude Code CLI processes
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

        // If --list flag is set, display process list
        if list {
            printProcessList(processes)
            return
        }

        // Kill processes
        let killer = ProcessKiller()
        let results = killer.killAll(processes: processes, force: force)

        printResults(results, processes: processes, force: force)

        // Exit with error if any kill failed
        let hasFailure = results.contains { !$0.success }
        if hasFailure {
            throw ExitCode.failure
        }
    }

    /// Displays the process list
    private func printProcessList(_ processes: [ClaudeCodeProcess]) {
        print("🔍 Claude Code Processes:")
        for process in processes {
            print("  \(process)")
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        let totalCPU = processes.reduce(0.0) { $0 + $1.cpuUsage }
        let totalMEM = processes.reduce(0.0) { $0 + $1.memoryUsage }
        let totalMB = processes.reduce(0.0) { $0 + $1.memoryMB }
        print("📊 Total: CPU: \(String(format: "%.1f", totalCPU))%, MEM: \(String(format: "%.1f", totalMEM))% / \(String(format: "%.1f", totalMB)) MB (\(processes.count) processes)")
    }

    /// Displays the kill results
    private func printResults(_ results: [KillResult], processes: [ClaudeCodeProcess], force: Bool) {
        let signalName = force ? "SIGKILL" : "SIGTERM"
        let successCount = results.filter(\.success).count
        let totalCount = results.count

        print("🔪 Killed \(successCount)/\(totalCount) Claude Code processes (\(signalName)):")
        for result in results {
            print("  \(result)")
        }

        let processByPID = Dictionary(uniqueKeysWithValues: processes.map { ($0.pid, $0) })
        let freedMB = results
            .filter(\.success)
            .compactMap { processByPID[$0.pid]?.memoryMB }
            .reduce(0.0, +)

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("💾 Memory freed: \(String(format: "%.1f", freedMB)) MB")
    }

    /// Outputs an error message to standard error
    private func printError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
