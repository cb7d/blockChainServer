//
//  Transaction.swift
//  App
//
//  Created by Felix on 2018/8/9.
//

import Foundation
import FluentSQLite
import Vapor

final class Transaction: Codable,SQLiteModel {
    var id: Int?
    var from: String
    var to: String
    var amount: Double
    
    init(from: String, to: String, amount: Double) {
        self.from = from
        self.to = to
        self.amount = amount
    }
}

extension Transaction: Content { }

extension Transaction: Migration { }

extension Transaction: Parameter { }
