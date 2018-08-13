//
//  Blockchain.swift
//  App
//
//  Created by Felix on 2018/8/9.
//

import Foundation
import FluentSQLite
import Vapor

final class Blockchain: Codable,SQLiteModel {
    
    var id: Int?
    
    var blocks: [Block] = [Block]()
    
    init() {
        
    }
    
    init(_ genesisBlock: Block) {
        self.addBlock(genesisBlock)
    }
    
    func addBlock(_ block: Block) {
        if self.blocks.isEmpty {
            // 添加创世区块
            // 第一个区块没有 previous hash
            block.previousHash = "0"
        } else {
            let previousBlock = getPreviousBlock()
            block.previousHash = previousBlock.hash
            block.index = self.blocks.count
        }
        
        block.hash = generateHash(for: block)
        self.blocks.append(block)
        block.message = "此区块已添加至区块链"
    }
    
    private func getPreviousBlock() -> Block {
        return self.blocks[self.blocks.count - 1]
    }
    
    private func displayBlock(_ block: Block) {
        print("------ 第 \(block.index) 个区块 --------")
        print("创建日期：\(block.dateCreated)")
        // print("数据：\(block.data)")
        print("Nonce：\(block.nonce)")
        print("前一个区块的哈希值：\(block.previousHash!)")
        print("哈希值：\(block.hash!)")
    }
    
    private func generateHash(for block: Block) -> String {
        var hash = block.key.sha1Hash()
        
        // 设置工作量证明
        while(!hash.hasPrefix("11")) {
            block.nonce += 1
            hash = block.key.sha1Hash()
            print(hash)
        }
        
        return hash
    }
}

extension Blockchain: Content { }

extension Blockchain: Migration { }

extension Blockchain: Parameter { }

