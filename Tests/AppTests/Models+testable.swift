//
//  Models+testable.swift
//  App
//
//  Created by Abdel on 10/16/20.
//

@testable import App
import FluentPostgreSQL
import Crypto

extension User {
    /*
    static func create(
        name: String = "Luke",
        username: String = "lukes",
        password: String = "password",
        on connection: PostgreSQLConnection
    ) throws -> User {
        let user = User(name: name, username: username, password: password)
        return try user.save(on: connection).wait()
    }
    */
    
    static func create(name: String = "Luke",
                       username: String? = nil,
                       on conn: PostgreSQLConnection) throws -> User {
        var createUsername: String
        if let suppliedUsername = username {
            createUsername = suppliedUsername
        } else {
            createUsername = UUID().uuidString
        }
        let password = try BCrypt.hash("password")
        let user = User(name: name, username: createUsername, password: password)
        return try user.save(on: conn).wait()
    }
}


extension Book {
    
    static func create(user: User? = nil,
                        title: String = "title",
                        authors: String = "author",
                        edition: String? = "1st",
                        read: Bool = false,
                        on connection: PostgreSQLConnection) throws -> Book {
        
        let bookUser = user == nil ? try User.create(on: connection) : user!
        let book = Book(userID: bookUser.id!, title: title, authors: authors, edition: edition, read: read)
        return try book.save(on: connection).wait()
        
    }
}


extension App.Category {
    static func create(name: String = "Random",
                       on connection: PostgreSQLConnection ) throws -> App.Category {
    let category = Category(name: name)
    return try category.save(on: connection).wait()
    }
}
