import XCTVapor
@testable import SwiftScout
import Vapor

final class AuthTests: XCTestCase {
    var app: Application!
    
    override func setUp() async throws {
        app = try await TestHelper.createTestApp()
        try await app.autoMigrate()
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await app.shutdown()
    }
    
    func testUserRegistration() async throws {
        let create = User.Create(
            email: "test@example.com",
            password: "password123",
            name: "Test User",
            role: .customer
        )
        
        try await app.test(.POST, "api/v1/auth/register", beforeRequest: { req in
            try req.content.encode(create)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.created)
            let user = try res.content.decode(User.self)
            XCTAssertEqual(user.name, "Test User")
            XCTAssertEqual(user.email, "test@example.com")
            XCTAssertEqual(user.role, UserRole.customer)
        })
    }
    
    func testUserLogin() async throws {
        // Create a test user first
        _ = try await TestHelper.createTestUser(
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            role: .customer,
            on: app
        )
        
        let loginRequest = LoginRequest(
            email: "test@example.com",
            password: "password123"
        )
        
        try await app.test(.POST, "api/v1/auth/login", beforeRequest: { req in
            try req.content.encode(loginRequest)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.ok)
            let tokenResponse = try res.content.decode(TokenResponse.self)
            XCTAssertNotNil(tokenResponse.token)
        })
    }
    
    static let allTests = [
        ("testUserRegistration", testUserRegistration),
        ("testUserLogin", testUserLogin)
    ]
} 