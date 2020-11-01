//
//  Category.swift
//  App
//
//  Created by Abdel on 10/15/20.
//

import Vapor
import FluentPostgreSQL

final class Category: Codable {
    
    typealias Database = PostgreSQLDatabase
    
    var id: Int?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Category {
    var books: Siblings<Category, Book, BookCategoryPivot> {
        return siblings()
    }
    
    static func addCategory(_ name: String, to book: Book,on req: Request) throws -> Future<Void> {
        return Category.query(on: req)
            .filter(\.name, .equal, name)
            .first()
            .flatMap(to: Void.self) { foundCategory in
                if let existingCategory = foundCategory {
                    return book.categories
                        .attach(existingCategory, on: req)
                        .transform(to: ())
                } else  {
                    let category = Category(name: name)
                    return category.save(on: req)
                        .flatMap(to: Void.self) { savedCategory in
                            return book.categories
                                .attach(savedCategory, on: req)
                                .transform(to: ())
                        }
                }
            }
    }
}

extension Category: PostgreSQLModel {}
extension Category: Migration {}
extension Category: Content {}
extension Category: Parameter {}
