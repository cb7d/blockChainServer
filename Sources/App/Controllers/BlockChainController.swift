//
//  BlockChainController.swift
//  App
//
//  Created by Felix on 2018/8/10.
//

import Foundation
import Vapor

struct BCError:LocalizedError {
    let name:String
}

final class BlockChainController {
    
    let bcService = BlockchainService()
    
    func addBlock(_ req: Request) throws -> Future<Block> {
        return bcService.addBlock(Block()).save(on: req)
    }
    
    func addTransaction(_ req: Request) throws -> Future<Block> {
        
        return try req.content.decode(Transaction.self).flatMap{ transation in
            return self.bcService.getLastBlock().addTransaction(transaction: transation).save(on: req)
        }
    }
    
    func findBlockChain(_ req: Request) throws -> Future<Blockchain> {
        return bcService.getBlockchain().save(on: req)
    }
    
    func registeNode(_ req: Request) throws -> Future<BlockChainNode> {
        
        return try req.content.decode(BlockChainNode.self).flatMap{ node in
            return self.bcService.registerNode(node).save(on: req)
        }
    }
    
    func allNodes(_ req: Request) throws -> Future<[BlockChainNode]> {
        
        return BlockChainNode.query(on: req).all()
    }
    
    
    func resolve(_ req: Request) throws -> Future<Blockchain> {

        let promise = req.eventLoop.newPromise(Blockchain.self)
        
        bcService.getAllNodes().forEach { node in
            
            guard let url = URL(string: "http://\(node.address)/blockchain") else {return promise.fail(error: BCError(name: "node error"))}
            
            URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                if let data = data {
                    guard let bc = try? JSONDecoder().decode(Blockchain.self, from: data) else {return promise.fail(error: BCError(name: "json error"))}
                    
                    if self.bcService.getBlockchain().blocks.count < bc.blocks.count {
                        self.bcService.getBlockchain().blocks = bc.blocks
                    }
                    promise.succeed(result: self.bcService.getBlockchain())
                } else {
                    promise.fail(error: BCError(name: "data Error"))
                }
            }).resume()
        }
        return promise.futureResult
    }
}
