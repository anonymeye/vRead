//
//  UserTests.swift
//  App
//
//  Created by Abdel on 10/16/20.
//

@testable import App
import Vapor
import XCTest
import FluentPostgreSQL

final class UserTests: XCTestCase {
    let usersName = "Alice"
    let usersUsername = "alicea"
    let password = "password"
    let usersURI = "/users/"
    var app: Application!
    var conn: PostgreSQLConnection!
    
    
    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        conn.close()
    }
    
    func testUsersCanBeRetrievedFromAPI() throws {
        let user = try User.create(
            name: usersName,
            username: usersUsername,
            on: conn)
        
        _ = try User.create(on: conn)
        let users = try app.getResponse( to: usersURI, decodeTo: [User.Public].self)
        XCTAssertEqual(users.count, 3)   // to account for the admin user
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, user.id)
    }
    
    func testUserCanBeSavedWithAPI() throws {
        
        let user = User(name: usersName, username: usersUsername, password: password)
        let receivedUser = try app.getResponse(
            to: usersURI,
            method: .POST,
            headers: ["Content-Type": "application/json"],
            data: user,
            decodeTo: User.Public.self,
            loggedInRequest: true)
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)
        
        let users = try app.getResponse( to: usersURI,
                                         decodeTo: [User.Public].self)
        
        XCTAssertEqual(users.count, 2)   // to account for the admin user
        XCTAssertEqual(users[0].name, usersName)
        XCTAssertEqual(users[0].username, usersUsername)
        XCTAssertEqual(users[0].id, receivedUser.id)
    }
    
    
    func testGettingASingleUserFromTheAPI() throws {
        let user = try User.create( name: usersName, username: usersUsername, on: conn)
        let receivedUser = try app.getResponse( to: "\(usersURI)\(user.id!)", decodeTo: User.Public.self)
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.id, user.id)
    }
    
    
    func testGettingAUsersAcronymsFromTheAPI() throws {
        let user = try User.create(on: conn)
        let title = "alchemist"
        let authors = "Paulo Coelho"
        let edition = "1st"
        let read = true
        let book1 = try Book.create(user: user, title: title, authors: authors, edition: edition, read: read, on: conn)
        _ = try Book.create(user: user, title: "java", authors: "Jean", edition: edition, read: read, on: conn)
        // 4
        let books = try app.getResponse(
            to: "\(usersURI)\(user.id!)/books", decodeTo: [Book].self)
    
        XCTAssertEqual(books.count, 2)
        XCTAssertEqual(books[0].id, book1.id)
        XCTAssertEqual(books[0].title, book1.title )
        XCTAssertEqual(books[0].authors, book1.authors)
        XCTAssertEqual(books[0].edition, book1.edition)
        XCTAssertEqual(books[0].read, book1.read)
    }
    
    static let allTests = [
      ("testUsersCanBeRetrievedFromAPI",
       testUsersCanBeRetrievedFromAPI),
      ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
      ("testGettingASingleUserFromTheAPI",
       testGettingASingleUserFromTheAPI),
      ("testGettingAUsersAcronymsFromTheAPI",
       testGettingAUsersAcronymsFromTheAPI)
    ]
    
    
    
    
}
