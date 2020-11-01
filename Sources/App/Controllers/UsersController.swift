//
//  UsersController.swift
//  App
//
//  Created by Abdel on 10/15/20.
//
import Vapor
import Crypto

final class UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("users")
        usersRoute.post(User.self, use: createHandler)
        usersRoute.get(use: getAllHandler)    // /users
        usersRoute.get(User.parameter, use: getHandler) //   /users/<userid>
        usersRoute.get(User.parameter, "books", use: getBooksHandler)
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup      = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup      = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(User.self, use: createHandler)
    }
    
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req).convertToPublic()
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).convertToPublic()
    }
    
    func getBooksHandler(_ req: Request) throws -> Future<[Book]> {
        return try req
            .parameters.next(User.self)
            .flatMap(to: [Book].self) { user in
                try user.books.query(on: req).all()
            }
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        // protect the route with the HTTP basic auth middleware, saves the user's identity in the request's auth cache
        let user  = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
}
