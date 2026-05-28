//
//  sentry-cli.swift
//  Sentry
//
//  Created by Monu Kumar on 28/05/26.
//

import Foundation

// Help text
func printHelp() {
    print("""
    Sentry CLI - Pipe command output to Sentry lock screen
    
    Usage:
      Pipe mode:
        <command> | sentry-cli [options]
      
      Subcommand mode:
        sentry-cli [options] -- <command> [arguments...]
        
      One-Shot mode:
        sentry-cli [options] -s <status> -m <message>
        
    Options:
      -t, --title <title>     Set the command title (default: "Command Progress")
      -s, --status <status>   One-Shot mode: Set status (running|success|failed|completed)
      -m, --message <msg>     One-Shot mode: Add a message line to display (can use multiple times)
      -c, --clear             Clear lock screen progress when finished (or in 3s for One-Shot)
      -h, --help              Show this help message
    """)
}

// Simple argument parser
var title = "Command Progress"
var clearOnExit = false
var statusOption: String? = nil
var messages: [String] = []
var commandArgs: [String] = []
var isSubcommandMode = false

var args = Array(CommandLine.arguments.dropFirst())
var i = 0
while i < args.count {
    let arg = args[i]
    if arg == "-h" || arg == "--help" {
        printHelp()
        exit(0)
    } else if arg == "-t" || arg == "--title" {
        if i + 1 < args.count {
            title = args[i + 1]
            i += 2
        } else {
            print("Error: Missing value for \(arg)")
            exit(1)
        }
    } else if arg == "-s" || arg == "--status" {
        if i + 1 < args.count {
            let statusVal = args[i + 1].lowercased()
            if ["running", "success", "failed", "completed"].contains(statusVal) {
                statusOption = statusVal
            } else {
                print("Error: Invalid status '\(args[i + 1])'. Must be one of: running, success, failed, completed")
                exit(1)
            }
            i += 2
        } else {
            print("Error: Missing value for \(arg)")
            exit(1)
        }
    } else if arg == "-m" || arg == "--message" {
        if i + 1 < args.count {
            messages.append(args[i + 1])
            i += 2
        } else {
            print("Error: Missing value for \(arg)")
            exit(1)
        }
    } else if arg == "-c" || arg == "--clear" {
        clearOnExit = true
        i += 1
    } else if arg == "--" {
        isSubcommandMode = true
        commandArgs = Array(args.dropFirst(i + 1))
        break
    } else {
        print("Unknown argument: \(arg)")
        printHelp()
        exit(1)
    }
}

// Configuration
let maxLines = 8
var outputBuffer: [String] = []
let notificationName = Notification.Name("com.monuk7735.sentry.cli.update")
let queue = DispatchQueue(label: "com.monuk7735.sentry.cli.buffer")

var lastNotificationTime = Date.distantPast
let rateLimitInterval: TimeInterval = 0.2 // Max 5 notifications per second
var isPendingNotification = false

func sendNotification(status: String) {
    let lines = queue.sync { outputBuffer }
    let userInfo: [String: Any] = [
        "title": title,
        "lines": lines,
        "status": status,
        "timestamp": Date().timeIntervalSince1970,
        "clearOnExit": clearOnExit
    ]
    
    // Post distributed notification
    DistributedNotificationCenter.default().postNotificationName(
        notificationName,
        object: nil,
        userInfo: userInfo,
        deliverImmediately: true
    )
    lastNotificationTime = Date()
    isPendingNotification = false
}

func queueNotification(status: String) {
    let now = Date()
    let elapsed = now.timeIntervalSince(lastNotificationTime)
    
    if elapsed >= rateLimitInterval {
        sendNotification(status: status)
    } else {
        if !isPendingNotification {
            isPendingNotification = true
            let delay = rateLimitInterval - elapsed
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                if isPendingNotification {
                    sendNotification(status: status)
                }
            }
        }
    }
}

func appendLine(_ line: String) {
    let trimmed = line.trimmingCharacters(in: .newlines)
    guard !trimmed.isEmpty else { return }
    
    queue.sync {
        outputBuffer.append(trimmed)
        if outputBuffer.count > maxLines {
            outputBuffer.removeFirst()
        }
    }
}

class LineBuffer {
    private var leftover = Data()
    private let callback: (String) -> Void
    
    init(callback: @escaping (String) -> Void) {
        self.callback = callback
    }
    
    func append(_ data: Data) {
        leftover.append(data)
        
        while let newlineIndex = leftover.firstIndex(of: UInt8(10)) { // 10 is '\n'
            let lineData = leftover.subdata(in: 0..<newlineIndex)
            if let line = String(data: lineData, encoding: .utf8) {
                callback(line)
            }
            leftover.removeSubrange(0...newlineIndex)
        }
    }
    
    func flush() {
        if !leftover.isEmpty {
            if let line = String(data: leftover, encoding: .utf8) {
                callback(line)
            }
            leftover = Data()
        }
    }
}

// Check if standard input is a pipe or TTY
let isStdinPipe = isatty(0) == 0

var isOneShotMode = false
if !isSubcommandMode && !isStdinPipe {
    if statusOption != nil || !messages.isEmpty {
        isOneShotMode = true
    } else {
        printHelp()
        exit(0)
    }
}

if isOneShotMode {
    // Populate the output buffer with the provided messages
    for msg in messages {
        let trimmed = msg.trimmingCharacters(in: .newlines)
        outputBuffer.append(trimmed)
    }
    
    let finalStatus = statusOption ?? "completed"
    sendNotification(status: finalStatus)
    Thread.sleep(forTimeInterval: 0.15) // Ensure notification reaches Sentry observer
    exit(0)
}

if !isSubcommandMode {
    // Pipe Mode: Read from stdin
    let lineBuffer = LineBuffer { line in
        print(line)
        appendLine(line)
        queueNotification(status: "running")
    }
    
    let stdinHandle = FileHandle.standardInput
    while true {
        let data = stdinHandle.availableData
        if data.isEmpty {
            break // EOF
        }
        lineBuffer.append(data)
    }
    lineBuffer.flush()
    sendNotification(status: "completed")
    Thread.sleep(forTimeInterval: 0.1) // Ensure notification reaches observer
} else {
    // Subcommand Mode: Run command and capture output
    guard !commandArgs.isEmpty else {
        print("Error: No command specified after --")
        exit(1)
    }
    
    // If the title wasn't overridden, use the command itself as the default title
    if title == "Command Progress" {
        title = commandArgs.joined(separator: " ")
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/zsh")
    let shellCommand = commandArgs.joined(separator: " ")
    process.arguments = ["-c", shellCommand]
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    let lineBuffer = LineBuffer { line in
        // Write to our stdout so the user can still see output in terminal
        print(line)
        
        appendLine(line)
        queueNotification(status: "running")
    }
    
    let readHandle = pipe.fileHandleForReading
    let group = DispatchGroup()
    group.enter()
    
    readHandle.readabilityHandler = { handle in
        let data = handle.availableData
        if data.isEmpty {
            readHandle.readabilityHandler = nil
            group.leave()
            return
        }
        lineBuffer.append(data)
    }
    
    do {
        try process.run()
        process.waitUntilExit()
        group.wait()
        
        lineBuffer.flush()
        
        let exitCode = process.terminationStatus
        let status = (exitCode == 0) ? "success" : "failed"
        sendNotification(status: status)
        Thread.sleep(forTimeInterval: 0.1) // Ensure notification reaches observer
        exit(exitCode)
    } catch {
        print("Failed to run command: \(error)")
        sendNotification(status: "failed")
        Thread.sleep(forTimeInterval: 0.1)
        exit(1)
    }
}
