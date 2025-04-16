import Foundation
import Vapor

struct PostgreSQLManager {
    private static let possiblePgPaths = [
        "/usr/local/bin",
        "/opt/homebrew/bin",
        "/usr/bin",
        "/bin"
    ]
    
    private static func findExecutable(_ name: String) throws -> URL {
        // First try using 'which' command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus == 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                return URL(fileURLWithPath: path)
            }
        }
        
        // If 'which' fails, try known locations
        for path in possiblePgPaths {
            let url = URL(fileURLWithPath: path).appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        throw Abort(.internalServerError, reason: "Could not find PostgreSQL executable: \(name)")
    }
    
    static func checkPostgreSQL() throws -> Bool {
        let process = Process()
        process.executableURL = try findExecutable("pg_isready")
        process.arguments = ["-h", "localhost", "-p", "5432"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        return process.terminationStatus == 0
    }
    
    static func startPostgreSQL() throws {
        let process = Process()
        process.executableURL = try findExecutable("pg_ctl")
        
        // Try to find PostgreSQL data directory
        let possibleDataDirs = [
            "/usr/local/var/postgres",
            "/opt/homebrew/var/postgres",
            "/var/lib/postgresql/data"
        ]
        
        var dataDir: String? = nil
        for dir in possibleDataDirs {
            if FileManager.default.fileExists(atPath: dir) {
                dataDir = dir
                break
            }
        }
        
        guard let dataDir = dataDir else {
            throw Abort(.internalServerError, reason: "Could not find PostgreSQL data directory")
        }
        
        process.arguments = ["start", "-D", dataDir]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw Abort(.internalServerError, reason: "Failed to start PostgreSQL: \(error)")
        }
        
        // Wait for PostgreSQL to be ready
        var attempts = 0
        while attempts < 10 {
            if try checkPostgreSQL() {
                return
            }
            Thread.sleep(forTimeInterval: 1)
            attempts += 1
        }
        
        throw Abort(.internalServerError, reason: "PostgreSQL failed to start within 10 seconds")
    }
    
    static func ensurePostgreSQLRunning() throws {
        let isRunning = try checkPostgreSQL()
        if !isRunning {
            print("PostgreSQL is not running. Attempting to start it...")
            try startPostgreSQL()
            print("PostgreSQL started successfully")
        } else {
            print("PostgreSQL is already running")
        }
    }
} 