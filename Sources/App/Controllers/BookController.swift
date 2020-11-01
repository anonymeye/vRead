//
//  BookController.swift
//  App
//
//  Created by Abdel on 10/11/20.
//

import Vapor
import Authentication

struct BookCreateData: Content {
    let title: String
    let authors: String
    let edition: String?
    let read: Bool
}

final class BookController: RouteCollection {
    func boot(router: Router) throws {
        let bookRoutes = router.grouped("books")
        bookRoutes.get(use: getAllBooks(_:))
        bookRoutes.get(Book.parameter, use: retrieveBook)
        bookRoutes.get("search", use: searchBook(_:))
        bookRoutes.get("first", use: getFirstBook(_:))
        bookRoutes.get("sorted", use: sortedBooks(_:))
        bookRoutes.get(Book.parameter, "user", use: getUserHandler)
        bookRoutes.get(Book.parameter, "categories", use: getCategoriesHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup      = bookRoutes.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        
        tokenAuthGroup.post(BookCreateData.self, use: createBook)
        tokenAuthGroup.put(Book.parameter, use: updateBook)
        tokenAuthGroup.delete(Book.parameter, use: deleteBook(_:))
        tokenAuthGroup.post(Book.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        tokenAuthGroup.delete(Book.parameter, "categories", Category.parameter, use: deleteBook)
        
    /*
        // BCryptDigest to verify passwords
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        // ensure requests contain valid authorization
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let protected           = bookRoutes.grouped(basicAuthMiddleware, guardAuthMiddleware)
        protected.post(Book.self, use: createBook)
    */
 
    }
    
    func getAllBooks(_ req: Request) throws -> Future<[Book]> {
        return Book.query(on: req).all()
    }
    
    func createBook(_ req: Request, data: BookCreateData) throws -> Future<Book> {
        let user = try req.requireAuthenticated(User.self)
        print("createBook")
        let book = try Book(userID: user.requireID(), title: data.title, authors: data.authors, edition: data.edition, read: data.read)
        print("error above")
        return book.save(on: req)
    }
    
    func retrieveBook(_ req: Request) throws -> Future<Book> {
        return try req.parameters.next(Book.self)
    }
    
    func updateBook(_ req: Request) throws -> Future<Book> {
        return try flatMap(to: Book.self, req.parameters.next(Book.self), req.content.decode(BookCreateData.self)) {
            book, updatedBook in
            book.title = updatedBook.title
            book.authors = updatedBook.authors
            book.edition = updatedBook.edition
            book.read = updatedBook.read
            
            let user = try req.requireAuthenticated(User.self)
            book.userID = try user.requireID()
            return book.save(on: req)
        }
    }
    
    func deleteBook(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Book.self)
            .delete(on: req)
            .transform(to: HTTPStatus.noContent)
    }
    
    func searchBook(_ req: Request) throws -> Future<[Book]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }
        
        print("searchTe ", searchTerm)
        return Book.query(on: req).group(.or) { or in
            or.filter(\.title, .equal, searchTerm)    //@FIX: it is not working !
            or.filter(\.authors, .equal, searchTerm)

//            or.filter(\.title == searchTerm)
//            or.filter(\.authors == searchTerm)
        }.all()
    }
    
    func getFirstBook(_ req: Request) throws -> Future<Book> {
        return Book.query(on: req)
            .first()
            .map(to: Book.self) { book in
                
                guard let book = book else {
                    throw Abort(.notFound)
                }
                return book
            }
    }
    
    func sortedBooks(_ req: Request) throws -> Future<[Book]> {
        return Book.query(on: req).sort(\.title, .ascending).all()
    }
    
    
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req
            .parameters.next(Book.self)
            .flatMap(to: User.Public.self) { book in
                book.user.get(on: req).convertToPublic()
            }
    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(
            to: HTTPStatus.self,
            req.parameters.next(Book.self),
            req.parameters.next(Category.self)) { book, category in
            return book.categories
                .attach(category, on: req)
                .transform(to: .created)
        }
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameters.next(Book.self)
            .flatMap(to: [Category].self) { book in
                try book.categories.query(on: req).all()
            }
    }
    
    func removeBooksHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try flatMap(to: HTTPStatus.self, req.parameters.next(Book.self), req.parameters.next(Category.self)
        ) { book, category in
            
            return book.categories
                .detach(category, on: req)
                .transform(to: .noContent)
        }
    }
    
 /*
    // // // // // //
    // different way
    // /// // // //
    func createHandler(_ req: Request) throws -> Future<Book> {
        return try req.content.decode(Book.self).flatMap(to: Book.self) { acronym in return acronym.save(on: req)
        }
    }
  */
}



