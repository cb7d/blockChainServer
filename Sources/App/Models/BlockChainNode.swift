//
//  BlockChainNode.swift
//  App
//
//  Created by Felix on 2018/8/11.
//

import FluentSQLite
import Vapor

final class BlockChainNode: Codable,SQLiteModel {
    var id: Int?
    var address :String
    
    init(addr:String) {
        address = addr
    }
}

extension BlockChainNode: Content { }

extension BlockChainNode: Migration { }

extension BlockChainNode: Parameter { }
