import Vapor
import Fluent

struct SystemController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let system = routes.grouped("system")
        system.post("shutdown", use: shutdown)
    }
    
    func shutdown(req: Request) async throws -> Response {
        // Only allow admin users to shutdown the system
        guard let user = try? req.auth.require(User.self) else {
            req.logger.error("Shutdown attempt by unauthenticated user")
            let response = Response(status: .unauthorized)
            try response.content.encode([
                "status": "error",
                "message": "You must be logged in to perform this action",
                "code": "UNAUTHORIZED"
            ])
            return response
        }
        
        guard user.role == .admin else {
            req.logger.error("Shutdown attempt by non-admin user: \(user.email)")
            let response = Response(status: .forbidden)
            try response.content.encode([
                "status": "error",
                "message": "Only administrators can shut down the system",
                "code": "FORBIDDEN"
            ])
            return response
        }
        
        req.logger.info("Shutdown initiated by admin user: \(user.email)")
        
        // Create a success response
        let response = Response(status: .ok)
        try response.content.encode([
            "status": "success",
            "message": "System shutdown initiated",
            "details": "The application will stop accepting new connections",
            "code": "SHUTDOWN_INITIATED"
        ])
        
        // Schedule the actual shutdown after sending the response
        // This ensures the response reaches the client
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            req.logger.info("Executing application shutdown")
            req.application.shutdown()
        }
        
        return response
    }
} 