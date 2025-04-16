@testable import SwiftScout
import XCTest
import XCTVapor
import Fluent
import FluentSQLiteDriver
import JWT
import Foundation
import Vapor

enum TestHelper {
    static func createTestApp() async throws -> Application {
        let app = try await Application.make(.testing)
        try configureTestApp(app)
        return app
    }
    
    static func configureTestApp(_ app: Application) throws {
        // Configure SQLite for testing
        app.databases.use(.sqlite(.memory), as: .sqlite)
        
        // Configure JWT
        app.jwt.signers.use(.hs256(key: "test-secret-key"))
        
        // Configure migrations
        app.migrations.add(CreateUser())
        app.migrations.add(CreateTicket())
        app.migrations.add(CreateConversation())
        app.migrations.add(CreateMessage())
        
        // Configure middleware
        app.middleware.use(ErrorMiddleware.default(environment: app.environment))
        
        // Configure content
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        ContentConfiguration.global.use(encoder: encoder, for: .json)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        ContentConfiguration.global.use(decoder: decoder, for: .json)
        
        // Register routes
        try routes(app)
        
        // Migrate database
        try app.autoMigrate().wait()
    }
    
    static func createTestUser(
        name: String,
        email: String,
        password: String,
        role: UserRole,
        on app: Application
    ) async throws -> User {
        let user = try User(
            name: name,
            email: email,
            password: password,
            role: role
        )
        try await user.save(on: app.db)
        return user
    }
    
    static func getAuthToken(for user: User, on app: Application) async throws -> String {
        let payload = UserPayload(
            subject: SubjectClaim(value: user.email),
            expiration: ExpirationClaim(value: Date().addingTimeInterval(3600)),
            userID: try user.requireID(),
            email: user.email,
            role: user.role
        )
        return try app.jwt.signers.sign(payload)
    }
    
    static func createTestTicket(
        title: String = "Test Ticket",
        description: String = "Test Description",
        priority: TicketPriority = .medium,
        status: TicketStatus = .open,
        customer: User,
        assignedTo: User? = nil,
        on app: Application
    ) async throws -> Ticket {
        let ticket = Ticket(
            title: title,
            description: description,
            priority: priority,
            status: status,
            customerID: try customer.requireID(),
            assignedToID: try assignedTo?.requireID()
        )
        try await ticket.save(on: app.db)
        return ticket
    }
    
    static func setupTestEnvironment() {
        // Set environment to testing
        setenv("ENVIRONMENT", "testing", 1)
        
        // Set SQLite configuration
        setenv("DATABASE_HOST", "localhost", 1)
        setenv("DATABASE_PORT", "5432", 1)
        setenv("DATABASE_USERNAME", "vapor_username", 1)
        setenv("DATABASE_PASSWORD", "vapor_password", 1)
        setenv("DATABASE_NAME", "vapor_database", 1)
        
        // Set JWT secret
        setenv("JWT_SECRET", "test-secret-key", 1)
        
        // Set Redis configuration
        setenv("REDIS_HOST", "localhost", 1)
        setenv("REDIS_PORT", "6379", 1)
    }
} 