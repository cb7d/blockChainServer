//
//  BlockChainService.swift
//  App
//
//  Created by Felix on 2018/8/10.
//

import Foundation
import Vapor

class BlockchainService {
    
    private var blockchain: Blockchain = Blockchain()
    private var nodes = [BlockChainNode]()
    
    init() {
        
    }
    
    func addBlock(_ block: Block) -> Block {
        self.blockchain.addBlock(block)
        return block
    }
    
    func getLastBlock() -> Block {
        
        guard let lastB = self.blockchain.blocks.last else {
            return addBlock(Block())
        }
        return lastB;
    }
    
    func getBlockchain() -> Blockchain {
        return self.blockchain
    }
    
    func registerNode(_ node:BlockChainNode) -> BlockChainNode {
        self.nodes.append(node)
        return node
    }
    
    func getAllNodes() -> [BlockChainNode] {
        return nodes
    }
}
