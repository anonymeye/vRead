//
//  User.swift
//  App
//
//  Created by Abdel on 10/15/20.
//

import Foundation
import Vapor
import FluentPostgreSQL
import Authentication

final class User: Codable {
    typealias Database = PostgreSQLDatabase
    
    var id: UUID?
    var name: String
    var username: String
    var password: String
    
    init(name: String, username: String, password:String) {
        self.name = name
        self.username = username
        self.password = password
    }
    
    // this will help so we don't send password in the response
    final class Public: Codable {
        var id: UUID?
        var name: String
        var username: String
        
        init(id: UUID?, name: String, username: String) {
            self.id = id
            self.name = name
            self.username = username
        }
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Parameter {}
extension User.Public: Content {}

extension User {
    var books: Children<User, Book> {
        return children(\.userID)
    }
}

extension User {
    func convertToPublic() -> User.Public {
        return User.Public(id: id, name: name, username: username)
    }
}

extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return self.map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

extension User: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) {
            builder in
            try addProperties(to: builder)
            builder.unique(on: \.username)   // make username as unique index, so it prevents duplicates
        }
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.username
    static let passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}


struct AdminUser: Migration {
    typealias Database = PostgreSQLDatabase

    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        // instead of hardcoding password, you can either read an environment variable or generate a random password and print it out.
        let password = try? BCrypt.hash("password")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        
        let user = User(
            name: "Admin",
            username: "admin",
            password: hashedPassword)
  
        return user.save(on: connection).transform(to: ())
    }

    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        return .done(on: connection)
    }
}

// *********** browser *********** //

//  allows Vapor to authenticate users with a username and password when they log in
// nothing to do here, since the necessary properties are in BasicAuthenticatable
extension User: PasswordAuthenticatable {}

//  allows the application to save and retrieve your user as part of a session
extension User: SessionAuthenticatable {}

