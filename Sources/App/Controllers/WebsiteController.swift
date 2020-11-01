//
//  WebsiteController.swift
//  App
//
//  Created by Abdel on 10/17/20.
//

import Vapor
import Leaf
import Fluent
import Authentication

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        /*
         In the API, you used GuardAuthenticationMiddleware to assert that the request contained an authenticated user. This middleware throws an authentication error if there’s no user, resulting in a 401 Unauthorized response to the client.
         On the web, this isn’t the best user experience. Instead, you use RedirectMiddleware to redirect users to the login page when they try to access a protected route without logging in first. Before you can use this redirect, you must first translate the session cookie, sent by the browser, into an authenticated user.
         */
        
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("books", Book.parameter,
                              use: bookHandler)
        authSessionRoutes.get("users", User.parameter, use: userHandler)
        authSessionRoutes.get("users", use: allUsersHandler)
        authSessionRoutes.get("categories", use: allCategoriesHandler)
        authSessionRoutes.get("categories", Category.parameter, use: categoryHandler)
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post(LoginPostData.self, at: "login", use: loginPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        authSessionRoutes.get("register", use: registerHandler) 
        authSessionRoutes.post(RegisterData.self, at: "register",
                               use: registerPostHandler)
        
        let protectedRoutes = authSessionRoutes .grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoutes.get(
            "books", Book.parameter, "edit", use: editBookHandler)
        protectedRoutes.post(
            "books", Book.parameter, "edit", use: editBookPostHandler)
        protectedRoutes.post(
            "books", Book.parameter, "delete", use: deleteBookHandler)
        protectedRoutes.get(
            "categories", Category.parameter, use: categoryHandler)
        protectedRoutes.get("books", "create", use: createBookHandler)
        protectedRoutes.post( CreateBookData.self,
                              at: "books", "create",
                              use: createBookPostHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Book.query(on: req).all()
            .flatMap(to: View.self) { books in
                let showCookieMessage = req.http.cookies["cookies-accepted"] == nil
                let booksData = books.isEmpty ? nil : books
                let userLoggedIn = try req.isAuthenticated(User.self)
                let context = IndexContext(title: "Homepage", books: booksData, userLoggedIn: userLoggedIn, showCookieMessage: showCookieMessage)
                return try req.view().render("index", context)
            }
    }
    
    func bookHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Book.self) .flatMap(to: View.self) { book in
            return book.user
                .get(on: req)
                .flatMap(to: View.self) { user in
                    let categories = try book.categories.query(on: req).all()
                    let context = BookContext( title: book.title, book: book,
                                               user: user, categories: categories)
                    return try req.view().render("book", context) }
        }
    }
    
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self) .flatMap(to: View.self) { user in

            return try user.books
                .query(on: req)
                .all()
                .flatMap(to: View.self) { books in

                    let context = UserContext( title: user.name,
                                               user: user,
                                               books: books)
                    return try req.view().render("user", context) }
        }
    }
    
    func allUsersHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req) .all()
            .flatMap(to: View.self) { users in
                let context = AllUsersContext(
                    title: "All Users",
                    users: users)
                return try req.view().render("allUsers", context) }
    }
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> {
        let categories = Category.query(on: req).all()
        let context = AllCategoriesContext(categories: categories)
        return try req.view().render("allCategories", context)
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Category.self) .flatMap(to: View.self) { category in
            let books = try category.books.query(on: req).all()
            let context = CategoryContext(
                title: category.name, category: category, books: books)
            return try req.view().render("category", context) }
    }
    
    func createBookHandler(_ req: Request) throws -> Future<View> {
        let token = try CryptoRandom() .generateData(count: 16) .base64EncodedString()
        let context = CreateBookContext(csrfToken: token)
        try req.session()["CSRF_TOKEN"] = token
        
        return try req.view().render("createBook", context)
    }
        
    func createBookPostHandler(
        _ req: Request,
        data: CreateBookData
    ) throws -> Future<Response> {
        
        let expectedToken = try req.session()["CSRF_TOKEN"]
        try req.session()["CSRF_TOKEN"] = nil

        guard expectedToken == data.csrfToken else {
            throw Abort(.badRequest) }
        let user = try req.requireAuthenticated(User.self)
        let book = Book(userID: try user.requireID(), title: data.title, authors: data.authors, edition: data.edition)
        
        return book.save(on: req)
            .flatMap(to: Response.self) { book in
                guard let id = book.id else {
                    throw Abort(.internalServerError) }

                var categorySaves: [Future<Void>] = []
                for category in data.categories ?? [] {
                    try categorySaves.append( Category.addCategory(category, to: book, on: req))
                }
                
                let redirect = req.redirect(to: "/books/\(id)")
                return categorySaves.flatten(on: req)
                    .transform(to: redirect)
            } }
    
    
    func editBookHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Book.self) .flatMap(to: View.self) { book in
            // let users = User.query(on: req).all()
            let categories = try book.categories.query(on: req).all()
            let context = EditBookContext( book: book, categories: categories)

            return try req.view().render("createBook", context) }
    }
    
    func editBookPostHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameters.next(Book.self), req.content
                            .decode(CreateBookData.self)) { book, data in
            
            let user = try req.requireAuthenticated(User.self)
            book.title = data.title
            book.authors = data.authors
            book.userID = try user.requireID()
            
            return book.save(on: req)
                .flatMap(to: Response.self) { savedBook in
                    guard let id = savedBook.id else {
                        throw Abort(.internalServerError)
                    }
                    
                    return try book.categories.query(on: req).all()
                        .flatMap(to: Response.self) { existingCategories in
                            let existingStringArray = existingCategories.map { $0.name }
                            let existingSet         = Set<String>(existingStringArray)
                            let newSet              = Set<String>(data.categories ?? [])
                            
                            let categoriesToAdd     = newSet.subtracting(existingSet)
                            let categoriesToRemove  = existingSet.subtracting(newSet)
                            
                            var categoryResults: [Future<Void>] = []
                            
                            for newCategory in categoriesToAdd {
                                categoryResults.append(
                                    try Category.addCategory(
                                        newCategory,
                                        to: book,
                                        on: req))
                            }
                            
                            for categoryNameToRemove in categoriesToRemove {
                                
                                let categoryToRemove = existingCategories.first {
                                    $0.name == categoryNameToRemove }
                                
                                if let category = categoryToRemove { categoryResults.append(
                                    book.categories.detach(category, on: req))
                                }
                            }
                            
                            return categoryResults
                                .flatten(on: req)
                                .transform(to: req.redirect(to: "/acronyms/\(id)"))
                        }
                }
        }
    }
    
    
    func deleteBookHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Book.self)
                                 .delete(on: req)
                                 .transform(to: req.redirect(to: "/"))
    }
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext
        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        return try req.view().render("login", context)
    }
    
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Response> {
        return User.authenticate(username: userData.username, password: userData.password,
                                 using: BCryptDigest(),
                                  on: req).map(to: Response.self) { user in
                                    guard let user = user else {
                                        return req.redirect(to: "/login?error")
                                    }
                                    try req.authenticateSession(user)
                                    return req.redirect(to: "/")
                                  }
    }
    
    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        return req.redirect(to: "/")
    }
    
    func registerHandler(_ req: Request) throws -> Future<View> {
        let context: RegisterContext
        if let message = req.query[String.self, at: "message"] {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }
        return try req.view().render("register", context)
    }
    
    func registerPostHandler(_ req: Request, data: RegisterData) throws -> Future<Response> {
        do {
            try data.validate()
        } catch (let error) {
            let redirect: String
            if let error = error as? ValidationError,
               let message = error.reason
                .addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed) {
                redirect = "/register?message=\(message)"
            } else {
                redirect = "/register?message=Unknown+error"
            }
            return req.future(req.redirect(to: redirect))
        }
        
        let password = try BCrypt.hash(data.password)
        let user     = User(name: data.name, username: data.username, password: password)
        
        return user.save(on: req).map(to: Response.self) { user in
            try req.authenticateSession(user)
            return req.redirect(to: "/")
        }
    }
}
