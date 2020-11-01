//
//  BookCategoryPivot.swift
//  App
//
//  Created by Abdel on 10/15/20.
//

import FluentPostgreSQL
import Foundation

/*
 BookCategoryPivot conforms to PostgreSQLUUIDPivot. This is a helper protocol on top of Fluent’s Pivot protocol. Also conform to ModifiablePivot. This allows you to use the syntactic sugar Vapor provides for adding and removing the relationships.
 */
final class BookCategoryPivot: PostgreSQLUUIDPivot, ModifiablePivot {
    
    typealias Database = PostgreSQLDatabase
    
    var id: UUID?
    var bookID: Book.ID
    var categoryID:  Category.ID
    
    typealias Left = Book
    typealias Right = Category
    
    static let leftIDKey: LeftIDKey = \.bookID
    static let rightIDKey: RightIDKey = \.categoryID
    
    init(_ book: Book, _ category: Category) throws {
        self.bookID = try book.requireID()
        self.categoryID = try category.requireID()
    }
}

extension BookCategoryPivot: Migration {
    
    static func prepare(on conn: PostgreSQLConnection) -> Future<Void> {
        return Database.create(self, on: conn) { builder in
            try addProperties(to: builder)
            // This sets up the foreign key constraint. .cascade sets a cascade schema reference action when you delete the tables. This means that the relationship is automatically removed instead of an error being thrown.
            builder.reference(from: \.bookID,
                              to: \Book.id,
                              onDelete: .cascade)
            builder.reference(from: \.categoryID, to: \Category.id, onDelete: .cascade)
        }
    }
}
