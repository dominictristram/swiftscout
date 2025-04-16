@testable import SwiftScout
import XCTVapor
import Fluent
import XCTest
import Vapor

final class IntegrationTests: XCTestCase {
    var app: Application!
    var adminToken: String!
    var agentToken: String!
    var customerToken: String!
    var admin: User!
    var agent: User!
    var customer: User!
    
    override func setUp() async throws {
        app = try await TestHelper.createTestApp()
        try await app.autoMigrate()
        
        // Create test users
        admin = try await TestHelper.createTestUser(
            name: "Admin",
            email: "admin@example.com",
            password: "password",
            role: .admin,
            on: app
        )
        
        agent = try await TestHelper.createTestUser(
            name: "Agent",
            email: "agent@example.com",
            password: "password",
            role: .agent,
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
        agentToken = try await TestHelper.getAuthToken(for: agent, on: app)
        customerToken = try await TestHelper.getAuthToken(for: customer, on: app)
    }
    
    override func tearDown() async throws {
        try await app.autoRevert()
        let app = self.app!
        try await app.eventLoopGroup.next().submit {
            app.shutdown()
        }.get()
    }
    
    func testCompleteTicketWorkflow() async throws {
        // Customer creates a ticket
        let ticketData = try JSONEncoder().encode([
            "title": "Test Ticket",
            "description": "This is a test ticket",
            "priority": "medium"
        ])
        
        var request = ClientRequest(method: .POST, url: URI(string: "api/v1/tickets"))
        request.headers.bearerAuthorization = BearerAuthorization(token: customerToken)
        request.headers.contentType = .json
        request.body = ByteBuffer(data: ticketData)
        
        let response = try await app.client.send(request)
        
        XCTAssertEqual(response.status, HTTPStatus.created)
        let ticket = try response.content.decode(Ticket.self)
        XCTAssertEqual(ticket.title, "Test Ticket")
        XCTAssertEqual(ticket.description, "This is a test ticket")
        XCTAssertEqual(ticket.priority, TicketPriority.medium)
        XCTAssertEqual(ticket.status, TicketStatus.open)
        XCTAssertEqual(ticket.$customer.id, customer.id)
        
        // Admin assigns ticket to agent
        let assignData = try JSONEncoder().encode([
            "assigned_to": agent.id?.uuidString
        ])
        
        var assignRequest = ClientRequest(method: .PUT, url: URI(string: "api/v1/tickets/\(ticket.id!)/assign"))
        assignRequest.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        assignRequest.headers.contentType = .json
        assignRequest.body = ByteBuffer(data: assignData)
        
        let assignResponse = try await app.client.send(assignRequest)
        
        XCTAssertEqual(assignResponse.status, HTTPStatus.ok)
        let assignedTicket = try assignResponse.content.decode(Ticket.self)
        XCTAssertEqual(assignedTicket.$assignedTo.id, agent.id)
        
        // Agent updates ticket status
        let updateData = try JSONEncoder().encode([
            "status": "in_progress"
        ])
        
        var updateRequest = ClientRequest(method: .PUT, url: URI(string: "api/v1/tickets/\(ticket.id!)"))
        updateRequest.headers.bearerAuthorization = BearerAuthorization(token: agentToken)
        updateRequest.headers.contentType = .json
        updateRequest.body = ByteBuffer(data: updateData)
        
        let updateResponse = try await app.client.send(updateRequest)
        
        XCTAssertEqual(updateResponse.status, HTTPStatus.ok)
        let updatedTicket = try updateResponse.content.decode(Ticket.self)
        XCTAssertEqual(updatedTicket.status, TicketStatus.inProgress)
    }
    
    func testTicketSearchAndFiltering() async throws {
        // Create test tickets
        let customer = try await TestHelper.createTestUser(
            name: "Test Customer",
            email: "test@example.com",
            password: "password",
            role: .customer,
            on: app
        )
        
        // Create tickets with different statuses and priorities
        _ = try await TestHelper.createTestTicket(
            title: "High Priority Ticket",
            description: "Test Description",
            priority: .high,
            status: .open,
            customer: customer,
            assignedTo: nil,
            on: app
        )
        
        _ = try await TestHelper.createTestTicket(
            title: "Medium Priority Ticket",
            description: "Test Description",
            priority: .medium,
            status: .inProgress,
            customer: customer,
            assignedTo: nil,
            on: app
        )
        
        // Test filtering by status
        var statusRequest = ClientRequest(method: .GET, url: URI(string: "api/v1/tickets?status=open"))
        statusRequest.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        let statusResponse = try await app.client.send(statusRequest)
        
        XCTAssertEqual(statusResponse.status, HTTPStatus.ok)
        let statusTickets = try statusResponse.content.decode([Ticket].self)
        XCTAssertEqual(statusTickets.count, 1)
        XCTAssertEqual(statusTickets[0].status, TicketStatus.open)
        
        // Test filtering by priority
        var priorityRequest = ClientRequest(method: .GET, url: URI(string: "api/v1/tickets?priority=medium"))
        priorityRequest.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        let priorityResponse = try await app.client.send(priorityRequest)
        
        XCTAssertEqual(priorityResponse.status, HTTPStatus.ok)
        let priorityTickets = try priorityResponse.content.decode([Ticket].self)
        XCTAssertEqual(priorityTickets.count, 1)
        XCTAssertEqual(priorityTickets[0].priority, TicketPriority.medium)
    }
    
    func testTicketAssignmentWorkflow() async throws {
        // Create a ticket as customer
        let ticketData = try JSONEncoder().encode([
            "title": "Test Ticket",
            "description": "Test Description",
            "priority": "medium",
            "status": "open"
        ])
        
        var request = ClientRequest(method: .POST, url: URI(string: "api/v1/tickets"))
        request.headers.bearerAuthorization = BearerAuthorization(token: customerToken)
        request.headers.contentType = .json
        request.body = ByteBuffer(data: ticketData)
        
        let response = try await app.client.send(request)
        
        XCTAssertEqual(response.status, HTTPStatus.created)
        let ticket = try response.content.decode(Ticket.self)
        XCTAssertEqual(ticket.title, "Test Ticket")
        XCTAssertEqual(ticket.description, "Test Description")
        XCTAssertEqual(ticket.priority, TicketPriority.medium)
        XCTAssertEqual(ticket.status, TicketStatus.open)
        
        // Admin assigns ticket to agent
        let assignData = try JSONEncoder().encode([
            "assigned_to": agent.id?.uuidString
        ])
        
        var assignRequest = ClientRequest(method: .PUT, url: URI(string: "api/v1/tickets/\(ticket.id!)/assign"))
        assignRequest.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        assignRequest.headers.contentType = .json
        assignRequest.body = ByteBuffer(data: assignData)
        
        let assignResponse = try await app.client.send(assignRequest)
        
        XCTAssertEqual(assignResponse.status, HTTPStatus.ok)
        let assignedTicket = try assignResponse.content.decode(Ticket.self)
        XCTAssertEqual(assignedTicket.$assignedTo.id, agent.id)
        
        // Agent updates ticket status
        let updateData = try JSONEncoder().encode([
            "status": "in_progress"
        ])
        
        var updateRequest = ClientRequest(method: .PUT, url: URI(string: "api/v1/tickets/\(ticket.id!)"))
        updateRequest.headers.bearerAuthorization = BearerAuthorization(token: agentToken)
        updateRequest.headers.contentType = .json
        updateRequest.body = ByteBuffer(data: updateData)
        
        let updateResponse = try await app.client.send(updateRequest)
        
        XCTAssertEqual(updateResponse.status, HTTPStatus.ok)
        let updatedTicket = try updateResponse.content.decode(Ticket.self)
        XCTAssertEqual(updatedTicket.status, TicketStatus.inProgress)
    }
    
    func testTicketFiltering() async throws {
        // Create test tickets with different statuses and priorities
        let ticket1 = try await TestHelper.createTestTicket(
            title: "Open Ticket",
            description: "Test Description",
            priority: .medium,
            status: .open,
            customer: customer,
            assignedTo: nil,
            on: app
        )
        
        _ = try await TestHelper.createTestTicket(
            title: "In Progress Ticket",
            description: "Test Description",
            priority: .high,
            status: .inProgress,
            customer: customer,
            assignedTo: agent,
            on: app
        )
        
        // Test filtering by status
        var statusRequest = ClientRequest(method: .GET, url: URI(string: "api/v1/tickets?status=open"))
        statusRequest.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        let statusResponse = try await app.client.send(statusRequest)
        
        XCTAssertEqual(statusResponse.status, HTTPStatus.ok)
        let tickets = try statusResponse.content.decode([Ticket].self)
        XCTAssertEqual(tickets.count, 1)
        XCTAssertEqual(tickets[0].id, ticket1.id)
        XCTAssertNil(tickets[0].$assignedTo.id)
        
        // Test filtering by priority
        var priorityRequest = ClientRequest(method: .GET, url: URI(string: "api/v1/tickets?priority=medium"))
        priorityRequest.headers.bearerAuthorization = BearerAuthorization(token: adminToken)
        let priorityResponse = try await app.client.send(priorityRequest)
        
        XCTAssertEqual(priorityResponse.status, HTTPStatus.ok)
        let priorityTickets = try priorityResponse.content.decode([Ticket].self)
        XCTAssertEqual(priorityTickets.count, 1)
        XCTAssertEqual(priorityTickets[0].id, ticket1.id)
        XCTAssertNil(priorityTickets[0].$assignedTo.id)
    }
    
    static let allTests = [
        ("testCompleteTicketWorkflow", testCompleteTicketWorkflow),
        ("testTicketSearchAndFiltering", testTicketSearchAndFiltering),
        ("testTicketAssignmentWorkflow", testTicketAssignmentWorkflow),
        ("testTicketFiltering", testTicketFiltering)
    ]
} 