import XCTVapor
@testable import SwiftScout
import Vapor

final class UserTests: XCTestCase {
    var app: Application!
    var adminToken: String!
    var admin: User!
    var customer: User!
    
    override func setUp() async throws {
        app = try await TestHelper.createTestApp()
        try await app.autoMigrate()
        
        // Create admin user
        admin = try await TestHelper.createTestUser(
            name: "Admin",
            email: "admin@example.com",
            password: "password",
            role: .admin,
            on: app
        )
        adminToken = try await TestHelper.getAuthToken(for: admin, on: app)
        
        // Create customer user
        customer = try await TestHelper.createTestUser(
            name: "Customer",
            email: "customer@example.com",
            password: "password",
            role: .customer,
            on: app
        )
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        app.shutdown()
    }
    
    func testListUsers() async throws {
        try await app.test(.GET, "api/v1/users", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.ok)
            let users = try res.content.decode([User].self)
            XCTAssertGreaterThan(users.count, 0)
        })
    }
    
    func testCreateUser() async throws {
        let userData = try JSONEncoder().encode([
            "name": "New User",
            "email": "newuser@example.com",
            "password": "password123",
            "role": "customer"
        ])
        
        try await app.test(.POST, "api/v1/users", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
            req.headers.contentType = .json
            req.body = ByteBuffer(data: userData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.created)
            let user = try res.content.decode(User.self)
            XCTAssertEqual(user.name, "New User")
            XCTAssertEqual(user.email, "newuser@example.com")
            XCTAssertEqual(user.role, .customer)
        })
    }
    
    func testUpdateUser() async throws {
        let user = try await TestHelper.createTestUser(
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            role: .customer,
            on: app
        )
        
        let updateData = try JSONEncoder().encode([
            "name": "Updated User",
            "email": "updated@example.com",
            "password": "newpassword123",
            "role": "agent"
        ])
        
        try await app.test(.PUT, "api/v1/users/\(user.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
            req.headers.contentType = .json
            req.body = ByteBuffer(data: updateData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.ok)
            let updatedUser = try res.content.decode(User.self)
            XCTAssertEqual(updatedUser.name, "Updated User")
            XCTAssertEqual(updatedUser.email, "updated@example.com")
            XCTAssertEqual(updatedUser.role, .agent)
        })
    }
    
    func testDeleteUser() async throws {
        let user = try await TestHelper.createTestUser(
            name: "Test User",
            email: "test@example.com",
            password: "password123",
            role: .customer,
            on: app
        )
        
        try await app.test(.DELETE, "api/v1/users/\(user.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.noContent)
        })
        
        // Verify user is deleted
        try await app.test(.GET, "api/v1/users/\(user.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.notFound)
        })
    }
    
    static let allTests = [
        ("testListUsers", testListUsers),
        ("testCreateUser", testCreateUser),
        ("testUpdateUser", testUpdateUser),
        ("testDeleteUser", testDeleteUser)
    ]
} 