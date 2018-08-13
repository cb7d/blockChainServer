//
//  Block.swift
//  App
//
//  Created by Felix on 2018/8/9.
//

import FluentSQLite
import Vapor

final class Block: Codable,SQLiteModel {
    var id: Int?
    var index: Int = 0
    var dateCreated: String
    var previousHash: String!
    var hash: String!
    var nonce: Int
    var message: String = ""
    private (set) var transactions: [Transaction] = [Transaction]()
    
    var key: String {
        get {
            let transactionsData = try! JSONEncoder().encode(transactions)
            let transactionsJSONString = String(data: transactionsData, encoding: .utf8)
            
            return String(index) + dateCreated + previousHash + transactionsJSONString! + String(nonce)
        }
    }
    
    @discardableResult
    func addTransaction(transaction: Transaction) -> Block{
        transactions.append(transaction)
        return self
    }
    
    init() {
        dateCreated = Date().toString()
        nonce = 0
        message = "挖出新的区块"
    }
    
    init(transaction: Transaction) {
        dateCreated = Date().toString()
        nonce = 0
        addTransaction(transaction: transaction)
    }
}

extension Block: Content { }

extension Block: Migration { }

extension Block: Parameter { }
