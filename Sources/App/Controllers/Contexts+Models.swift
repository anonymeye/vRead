//
//  Contexts+Models.swift
//  App
//
//  Created by Abdel on 10/17/20.
//

import Foundation
import Vapor

struct IndexContext: Encodable {
    let title: String
    let books: [Book]?
    let userLoggedIn: Bool
    let showCookieMessage: Bool
}

struct BookContext: Encodable {
    let title: String
    let book: Book
    let user: User
    let categories: Future<[Category]>
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let books: [Book]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCategoriesContext: Encodable {
    let title = "All Categories"
    let categories: Future<[Category]>
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let books: Future<[Book]>
}

struct CreateBookContext: Encodable {
    let title = "Create A Book"
    let csrfToken: String
    // let users: Future<[User]>
}


struct EditBookContext: Encodable {
    let title = "Edit Book"
    let book: Book
    // let users: Future<[User]>
    let editing = true
    let categories: Future<[Category]>
}


struct CreateBookData: Content {
    // let userID: User.ID
    let title: String
    let authors: String
    let edition: String
    let categories: [String]?
    let csrfToken: String
}


struct LoginContext: Encodable {
    let title = "log in"
    let loginError: Bool
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginPostData: Content {
    let username: String
    let password: String
}

struct RegisterContext: Encodable {
    let title = "Register"
    let message: String?
    init(message: String? = nil) {
    self.message = message }
}

struct RegisterData: Content {
    let name: String
    let username: String
    let password: String
    let confirmPassword: String
}

extension RegisterData: Validatable, Reflectable {
    
    static func validations() throws -> Validations<RegisterData> {
        var validations = Validations(RegisterData.self)
        try validations.add(\.name, .ascii)
        try validations.add(\.username,
                            .alphanumeric && .count(3...))
        try validations.add(\.password, .count(8...))
        
        validations.add("passwords match") { model in
            guard model.password == model.confirmPassword else {
                throw BasicValidationError("passwords don’t match") }
            }
        
        return validations
    }
}
