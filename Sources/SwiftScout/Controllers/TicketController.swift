import Vapor
import Fluent

struct CreateTicketData: Content {
    let title: String
    let description: String
    let priority: TicketPriority
}

struct CreateMessageData: Content {
    let content: String
}

struct TicketController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let tickets = routes.grouped("tickets")
        let protected = tickets.grouped(User.authenticator())
        
        protected.get(use: index)
        protected.post(use: create)
        protected.group(":ticketID") { ticket in
            ticket.get(use: get)
            ticket.put(use: update)
            ticket.delete(use: delete)
            ticket.put("assign", use: assign)
            ticket.post("messages", use: createMessage)
        }
    }
    
    @Sendable
    func index(req: Request) async throws -> [Ticket] {
        try await Ticket.query(on: req.db).all()
    }
    
    @Sendable
    func create(req: Request) async throws -> Ticket {
        let user = try req.auth.require(User.self)
        let ticket = try req.content.decode(Ticket.self)
        ticket.createdByID = user.id
        try await ticket.save(on: req.db)
        return ticket
    }
    
    @Sendable
    func get(req: Request) async throws -> Ticket {
        guard let ticket = try await Ticket.find(req.parameters.get("ticketID"), on: req.db) else {
            throw Abort(.notFound)
        }
        return ticket
    }
    
    @Sendable
    func update(req: Request) async throws -> Ticket {
        let user = try req.auth.require(User.self)
        guard let ticket = try await Ticket.find(req.parameters.get("ticketID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Only the ticket creator, assigned agent, or admin can update the ticket
        if user.id != ticket.createdByID && user.id != ticket.assignedToID && user.role != .admin {
            throw Abort(.forbidden)
        }
        
        let updatedTicket = try req.content.decode(Ticket.self)
        ticket.title = updatedTicket.title
        ticket.description = updatedTicket.description
        ticket.status = updatedTicket.status
        ticket.priority = updatedTicket.priority
        try await ticket.save(on: req.db)
        return ticket
    }
    
    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let ticket = try await Ticket.find(req.parameters.get("ticketID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Only the ticket creator or admin can delete the ticket
        if user.id != ticket.createdByID && user.role != .admin {
            throw Abort(.forbidden)
        }
        
        try await ticket.delete(on: req.db)
        return .ok
    }
    
    @Sendable
    func assign(req: Request) async throws -> Ticket {
        let user = try req.auth.require(User.self)
        guard user.role == .admin || user.role == .agent else {
            throw Abort(.forbidden)
        }
        
        guard let ticket = try await Ticket.find(req.parameters.get("ticketID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let assignRequest = try req.content.decode(AssignRequest.self)
        guard let agent = try await User.find(assignRequest.agentID, on: req.db) else {
            throw Abort(.notFound, reason: "Agent not found")
        }
        
        // Only assign to agents
        guard agent.role == .agent else {
            throw Abort(.badRequest, reason: "Can only assign tickets to agents")
        }
        
        ticket.assignedToID = agent.id
        try await ticket.save(on: req.db)
        return ticket
    }
    
    @Sendable
    func createMessage(req: Request) async throws -> Message {
        let user = try req.auth.require(User.self)
        guard let ticket = try await Ticket.find(req.parameters.get("ticketID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        // Only the ticket creator, assigned agent, or admin can add messages
        if user.id != ticket.createdByID && user.id != ticket.assignedToID && user.role != .admin {
            throw Abort(.forbidden)
        }
        
        let data = try req.content.decode(CreateMessageRequest.self)
        let message = Message(
            content: data.content,
            conversationId: ticket.id!,
            userId: user.id!,
            ticketId: ticket.id!
        )
        
        try await message.save(on: req.db)
        return message
    }
}

struct AssignRequest: Content {
    let agentID: UUID
}

struct CreateMessageRequest: Content {
    let content: String
} 