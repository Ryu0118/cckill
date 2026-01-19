import Foundation
import Subprocess

/// A struct for detecting Claude Code CLI processes
public struct ClaudeCodeProcessFinder: Sendable {
    public init() {}

    /// Detects Claude Code CLI processes
    ///
    /// Detection criteria:
    /// 1. Process name (comm) is `claude`
    /// 2. Command line arguments do not contain `/Applications/Claude.app`
    /// 3. Command line arguments start with `claude`
    public func findProcesses() async throws -> [ClaudeCodeProcess] {
        let output = try await runPsCommand()
        return parseOutput(output)
    }

    /// Executes the ps command
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

    /// Parses the ps command output
    private func parseOutput(_ output: String) -> [ClaudeCodeProcess] {
        var processes: [ClaudeCodeProcess] = []
        let lines = output.components(separatedBy: "\n")

        // Skip header line
        for line in lines.dropFirst() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if let process = parseLine(trimmed) {
                processes.append(process)
            }
        }

        return processes
    }

    /// Parses a single line and returns a ClaudeCodeProcess (nil if criteria not met)
    private func parseLine(_ line: String) -> ClaudeCodeProcess? {
        // ps -eo pid,comm,args,pcpu,pmem output format:
        // PID COMM ARGS %CPU %MEM
        // Numbers are right-aligned, strings are left-aligned

        let components = line.split(separator: " ", omittingEmptySubsequences: true)
        guard components.count >= 5 else { return nil }

        // PID
        guard let pid = Int32(components[0]) else { return nil }

        // COMM (process name)
        let comm = String(components[1])

        // Criterion 1: Process name must be claude
        guard comm == "claude" else { return nil }

        // Last two columns are %CPU and %MEM
        guard let memUsage = Double(components[components.count - 1]),
              let cpuUsage = Double(components[components.count - 2]) else { return nil }

        // ARGS (command line arguments) - from after COMM to before %CPU
        let argsComponents = components[2..<(components.count - 2)]
        let args = argsComponents.joined(separator: " ")

        // Criterion 2: Must not contain /Applications/Claude.app
        guard !args.contains("/Applications/Claude.app") else { return nil }

        // Criterion 3: Command must start with claude
        guard args.hasPrefix("claude") else { return nil }

        return ClaudeCodeProcess(
            pid: pid,
            command: args,
            cpuUsage: cpuUsage,
            memoryUsage: memUsage
        )
    }
}
