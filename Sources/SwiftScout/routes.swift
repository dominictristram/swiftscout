import Vapor

func routes(_ app: Application) throws {
    // Root route
    app.get { req -> Response in
        // Check for token in Authorization header
        if let authHeader = req.headers.first(name: "Authorization"),
           authHeader.hasPrefix("Bearer ") {
            let token = String(authHeader.dropFirst(7))
            do {
                // Verify token and redirect to dashboard if valid
                _ = try req.jwt.verify(token, as: UserPayload.self)
                return Response(
                    status: .seeOther,
                    headers: ["Location": "/dashboard"]
                )
            } catch {
                // Token invalid, show login page
            }
        }
        
        // Show landing page for unauthenticated users
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>SwiftScout</title>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
            <style>
                body { padding-top: 2rem; }
                .container { max-width: 960px; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="row justify-content-center">
                    <div class="col-md-8 text-center">
                        <h1 class="display-4 mb-4">Welcome to SwiftScout</h1>
                        <p class="lead mb-4">Your ticket management solution</p>
                        <div class="d-grid gap-2 d-sm-flex justify-content-sm-center">
                            <a href="/login" class="btn btn-primary btn-lg px-4 gap-3">Login</a>
                            <a href="/register" class="btn btn-outline-secondary btn-lg px-4">Register</a>
                        </div>
                    </div>
                </div>
            </div>
            <script>
                // Add token to all requests
                document.addEventListener('DOMContentLoaded', () => {
                    const token = localStorage.getItem('token');
                    if (token) {
                        // Add token to all fetch requests
                        const originalFetch = window.fetch;
                        window.fetch = async function(url, options = {}) {
                            options.headers = options.headers || {};
                            options.headers['Authorization'] = `Bearer ${token}`;
                            return originalFetch(url, options);
                        };
                    }
                });
            </script>
        </body>
        </html>
        """
        
        return Response(
            status: .ok,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: .init(string: html)
        )
    }
    
    // Login page
    app.get("login") { req -> Response in
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Login - SwiftScout</title>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
            <style>
                body { padding-top: 2rem; }
                .container { max-width: 400px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1 class="text-center mb-4">Login</h1>
                <form id="loginForm">
                    <div class="mb-3">
                        <label for="email" class="form-label">Email</label>
                        <input type="email" class="form-control" id="email" required>
                    </div>
                    <div class="mb-3">
                        <label for="password" class="form-label">Password</label>
                        <input type="password" class="form-control" id="password" required>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Login</button>
                    <div id="error" class="alert alert-danger mt-3" style="display: none;"></div>
                </form>
                <div class="text-center mt-3">
                    <a href="/">Back to Home</a>
                </div>
            </div>
            <script>
                document.getElementById('loginForm').addEventListener('submit', async (e) => {
                    e.preventDefault();
                    const errorDiv = document.getElementById('error');
                    errorDiv.style.display = 'none';
                    
                    try {
                        const response = await fetch('/api/v1/auth/login', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                            },
                            body: JSON.stringify({
                                email: document.getElementById('email').value,
                                password: document.getElementById('password').value
                            })
                        });
                        
                        if (!response.ok) {
                            const error = await response.json();
                            throw new Error(error.reason || 'Login failed');
                        }
                        
                        const result = await response.json();
                        localStorage.setItem('token', result.token);
                        document.cookie = `token=${result.token}; path=/`;
                        window.location.href = '/dashboard';
                    } catch (error) {
                        errorDiv.textContent = error.message;
                        errorDiv.style.display = 'block';
                    }
                });
            </script>
        </body>
        </html>
        """
        
        return Response(
            status: .ok,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: .init(string: html)
        )
    }
    
    // Register page
    app.get("register") { req -> Response in
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Register - SwiftScout</title>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
            <style>
                body { padding-top: 2rem; }
                .container { max-width: 400px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1 class="text-center mb-4">Register</h1>
                <form id="registerForm">
                    <div class="mb-3">
                        <label for="name" class="form-label">Name</label>
                        <input type="text" class="form-control" id="name" required>
                    </div>
                    <div class="mb-3">
                        <label for="email" class="form-label">Email</label>
                        <input type="email" class="form-control" id="email" required>
                    </div>
                    <div class="mb-3">
                        <label for="password" class="form-label">Password</label>
                        <input type="password" class="form-control" id="password" required>
                    </div>
                    <div class="mb-3">
                        <label for="role" class="form-label">Role</label>
                        <select class="form-select" id="role" required>
                            <option value="customer">Customer</option>
                            <option value="agent">Agent</option>
                            <option value="admin">Admin</option>
                        </select>
                    </div>
                    <button type="submit" class="btn btn-primary w-100">Register</button>
                    <div id="error" class="alert alert-danger mt-3" style="display: none;"></div>
                </form>
                <div class="text-center mt-3">
                    <a href="/">Back to Home</a>
                </div>
            </div>
            <script>
                document.getElementById('registerForm').addEventListener('submit', async (e) => {
                    e.preventDefault();
                    const errorDiv = document.getElementById('error');
                    errorDiv.style.display = 'none';
                    
                    try {
                        const response = await fetch('/api/v1/auth/register', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                            },
                            body: JSON.stringify({
                                name: document.getElementById('name').value,
                                email: document.getElementById('email').value,
                                password: document.getElementById('password').value,
                                role: document.getElementById('role').value
                            })
                        });
                        
                        if (!response.ok) {
                            const error = await response.json();
                            throw new Error(error.reason || 'Registration failed');
                        }
                        
                        const result = await response.json();
                        localStorage.setItem('token', result.token);
                        document.cookie = `token=${result.token}; path=/`;
                        window.location.href = '/dashboard';
                    } catch (error) {
                        errorDiv.textContent = error.message;
                        errorDiv.style.display = 'block';
                    }
                });
            </script>
        </body>
        </html>
        """
        
        return Response(
            status: .ok,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: .init(string: html)
        )
    }
    
    // Dashboard route
    app.get("dashboard") { req async throws -> View in
        // Check for token in Authorization header, cookie, or query parameter
        let token: String?
        if let authHeader = req.headers.first(name: "Authorization"),
           authHeader.hasPrefix("Bearer ") {
            token = String(authHeader.dropFirst(7))
        } else if let cookieToken = req.cookies["token"]?.string {
            token = cookieToken
        } else if let queryToken = req.query[String.self, at: "token"] {
            token = queryToken
        } else {
            throw Abort(.unauthorized)
        }
        
        // Verify token and get user
        let user = try req.jwt.verify(token!, as: UserPayload.self)
        guard let dbUser = try await User.find(user.userID, on: req.db) else {
            throw Abort(.unauthorized)
        }
        
        print("Dashboard accessed by user: \(dbUser.email)")
        print("User role: \(dbUser.role)")
        
        // Get email settings if user is admin
        var emailSettings: EmailSettings?
        if dbUser.role == .admin {
            emailSettings = try await EmailSettings.query(on: req.db).first()
        }
        
        // Get all users if admin
        var users: [User]?
        if dbUser.role == .admin {
            users = try await User.query(on: req.db).all()
        }
        
        let context = DashboardContext(
            user: dbUser,
            emailSettings: emailSettings,
            users: users
        )
        
        return try await req.view.render("dashboard", context)
    }
    
    // Public routes
    let publicRoutes = app.grouped("api", "v1")
    publicRoutes.group("auth") { auth in
        let authController = AuthController()
        auth.post("register", use: authController.register)
        auth.post("login", use: authController.login)
    }
    
    // Protected routes
    let protectedRoutes = app.grouped("api", "v1").grouped(User.authenticator())
    
    // Settings routes
    protectedRoutes.group("settings") { settings in
        let settingsController = SettingsController()
        settings.get("email", use: settingsController.getEmailSettings)
        settings.post("email", use: settingsController.updateEmailSettings)
    }
    
    // Ticket routes
    protectedRoutes.group("tickets") { tickets in
        let ticketController = TicketController()
        tickets.get(use: ticketController.index)
        tickets.post(use: ticketController.create)
        tickets.group(":ticketID") { ticket in
            ticket.put(use: ticketController.update)
            ticket.delete(use: ticketController.delete)
            ticket.put("assign", use: ticketController.assign)
            ticket.post("messages", use: ticketController.createMessage)
        }
    }
    
    // User routes
    protectedRoutes.group("users") { users in
        let userController = UserController()
        users.get(use: userController.index)
        users.post(use: userController.create)
        users.group(":userID") { user in
            user.get(use: userController.show)
            user.put(use: userController.update)
            user.delete(use: userController.delete)
        }
    }
} 