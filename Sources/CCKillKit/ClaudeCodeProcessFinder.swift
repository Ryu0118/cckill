import Foundation
import RegexBuilder
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
        var processes = parseOutput(output)

        // Get accurate memory footprint for each process
        for i in processes.indices {
            if let footprintMB = await getMemoryFootprint(pid: processes[i].pid) {
                processes[i] = ClaudeCodeProcess(
                    pid: processes[i].pid,
                    command: processes[i].command,
                    cpuUsage: processes[i].cpuUsage,
                    memoryMB: footprintMB
                )
            }
        }

        return processes
    }

    /// Executes the ps command
    private func runPsCommand() async throws -> String {
        let result = try await Subprocess.run(
            .path("/bin/ps"),
            arguments: ["-eo", "pid,comm,pcpu,args"],
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

    /// Gets memory footprint for a process using the footprint command
    private func getMemoryFootprint(pid: pid_t) async -> Double? {
        do {
            let result = try await Subprocess.run(
                .path("/usr/bin/footprint"),
                arguments: ["-p", String(pid)],
                output: .string(limit: 1024 * 1024)
            )

            guard result.terminationStatus.isSuccess,
                  let output = result.standardOutput else {
                return nil
            }

            return parseFootprintOutput(output)
        } catch {
            return nil
        }
    }

    /// Parses footprint command output to extract memory in MB
    /// Example: "Footprint: 821 MB" or "Footprint: 1.5 GB"
    private func parseFootprintOutput(_ output: String) -> Double? {
        let regex = Regex {
            "Footprint:"
            OneOrMore(.whitespace)
            Capture {
                OneOrMore(.digit)
                Optionally {
                    "."
                    OneOrMore(.digit)
                }
            }
            OneOrMore(.whitespace)
            Capture {
                ChoiceOf {
                    "KB"
                    "MB"
                    "GB"
                }
            }
        }

        guard let match = output.firstMatch(of: regex),
              let value = Double(match.1) else {
            return nil
        }

        let unit = String(match.2)
        switch unit {
        case "GB": return value * 1024
        case "KB": return value / 1024
        default: return value  // MB
        }
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
        // ps -eo pid,comm,pcpu,args output format:
        // PID COMM %CPU ARGS
        // Numbers are right-aligned, strings are left-aligned

        let components = line.split(separator: " ", maxSplits: 3, omittingEmptySubsequences: true)
        guard components.count >= 4 else { return nil }

        // PID
        guard let pid = Int32(components[0]) else { return nil }

        // COMM (process name)
        let comm = String(components[1])

        // Criterion 1: Process name must be claude
        guard comm == "claude" else { return nil }

        // %CPU
        guard let cpuUsage = Double(components[2]) else { return nil }

        // ARGS (the rest of the line)
        let args = String(components[3])

        // Criterion 2: Must not contain /Applications/Claude.app
        guard !args.contains("/Applications/Claude.app") else { return nil }

        // Criterion 3: Command must start with claude
        guard args.hasPrefix("claude") else { return nil }

        return ClaudeCodeProcess(
            pid: pid,
            command: args,
            cpuUsage: cpuUsage,
            memoryMB: 0  // Will be filled in later
        )
    }
}
