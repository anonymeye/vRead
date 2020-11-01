//
//  Book.swift
//  App
//
//  Created by Abdel on 10/11/20.
//

import Vapor
import FluentPostgreSQL

final class Book: Codable {
    typealias Database = PostgreSQLDatabase
    
    var id: Int?   //@fix; UUID?  --> extension Book: PostgreSQLUUIDModel {}
    var title: String
    var authors: String  
    var edition: String?
    var read: Bool?

    var userID: User.ID
    
    init(userID: User.ID, title: String, authors: String, edition: String?, read: Bool = false) {
        self.userID = userID
        self.title = title
        self.authors = authors
        self.edition  = edition
        self.read = read
    }
}

extension Book {
    var user: Parent<Book, User> {
        return parent(\.userID)
    }
    
    var categories: Siblings<Book, Category, BookCategoryPivot> {
        return siblings()
    }
}

extension Book: PostgreSQLModel {}
/// allows: to be used as a dynamic migration
extension Book: Migration {
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
        }
    }
}
/// allows to be encoded and decoded form HTTP messages
extension Book: Content {}
/// allows to be used as a dynamic paramter in route definitions
extension Book: Parameter {}

/*
 Using foreign key constraints has a number of benefits:
 • It ensures you can’t create book with users that don’t exist.
 • You can’t delete users until you’ve deleted all their books.
 • You can’t delete the user table until you’ve deleted the book table.
 */
