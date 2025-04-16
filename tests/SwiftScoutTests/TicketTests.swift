import XCTVapor
@testable import SwiftScout
import Vapor

final class TicketTests: XCTestCase {
    var app: Application!
    var adminToken: String!
    var customerToken: String!
    var admin: User!
    var customer: User!
    
    override func setUp() async throws {
        app = try await TestHelper.createTestApp()
        try await app.autoMigrate()
        
        // Create admin and customer users
        admin = try await TestHelper.createTestUser(
            name: "Admin",
            email: "admin@example.com",
            password: "password",
            role: .admin,
            on: app
        )
        
        customer = try await TestHelper.createTestUser(
            name: "Customer",
            email: "customer@example.com",
            password: "password",
            role: .customer,
            on: app
        )
        
        // Get tokens
        adminToken = try await TestHelper.getAuthToken(for: admin, on: app)
        customerToken = try await TestHelper.getAuthToken(for: customer, on: app)
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        try await app.shutdown()
    }
    
    func testCreateTicket() async throws {
        let ticketData = try JSONEncoder().encode([
            "title": "Test Ticket",
            "description": "Test Description",
            "priority": "medium",
            "status": "open"
        ])
        
        try await app.test(.POST, "api/v1/tickets", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: customerToken)
            req.headers.contentType = .json
            req.body = ByteBuffer(data: ticketData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.created)
            let ticket = try res.content.decode(Ticket.self)
            XCTAssertEqual(ticket.title, "Test Ticket")
            XCTAssertEqual(ticket.description, "Test Description")
            XCTAssertEqual(ticket.priority, TicketPriority.medium)
            XCTAssertEqual(ticket.status, TicketStatus.open)
        })
    }
    
    func testListTickets() async throws {
        // Create a test ticket first
        let ticket = try await TestHelper.createTestTicket(
            title: "Test Ticket",
            description: "Test Description",
            priority: .medium,
            status: .open,
            customer: customer,
            assignedTo: nil,
            on: app
        )
        
        try await app.test(.GET, "api/v1/tickets", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.ok)
            let tickets = try res.content.decode([Ticket].self)
            XCTAssertEqual(tickets.count, 1)
            XCTAssertEqual(tickets[0].id, ticket.id)
        })
    }
    
    func testUpdateTicket() async throws {
        // Create a test ticket first
        let ticket = try await TestHelper.createTestTicket(
            title: "Test Ticket",
            description: "Test Description",
            priority: .medium,
            status: .open,
            customer: customer,
            assignedTo: nil,
            on: app
        )
        
        let updateData = try JSONEncoder().encode([
            "title": "Updated Ticket",
            "description": "Updated Description",
            "priority": "high",
            "status": "in_progress"
        ])
        
        try await app.test(.PUT, "api/v1/tickets/\(ticket.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
            req.headers.contentType = .json
            req.body = ByteBuffer(data: updateData)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.ok)
            let updatedTicket = try res.content.decode(Ticket.self)
            XCTAssertEqual(updatedTicket.title, "Updated Ticket")
            XCTAssertEqual(updatedTicket.description, "Updated Description")
            XCTAssertEqual(updatedTicket.priority, TicketPriority.high)
            XCTAssertEqual(updatedTicket.status, TicketStatus.inProgress)
        })
    }
    
    func testDeleteTicket() async throws {
        // Create a test ticket first
        let ticket = try await TestHelper.createTestTicket(
            title: "Test Ticket",
            description: "Test Description",
            priority: .medium,
            status: .open,
            customer: customer,
            assignedTo: nil,
            on: app
        )
        
        try await app.test(.DELETE, "api/v1/tickets/\(ticket.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.noContent)
        })
        
        // Verify ticket is deleted
        try await app.test(.GET, "api/v1/tickets/\(ticket.id!)", beforeRequest: { req in
            req.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        }, afterResponse: { res in
            XCTAssertEqual(res.status, HTTPStatus.notFound)
        })
    }
} 