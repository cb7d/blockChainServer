# BlockChainServer

[源码地址](https://github.com/FelixScat/blockChainServer)

最近身边的许多人都开始玩比特币，虽然本人不炒但是想稍微了解一下其中的原理，所以就练手写了一个简易版的区块链系统。


### So 、 What is the BlockChain (区块链) ?

这里引用一下Google的结果

> 所谓区块链技术 ， 简称BT（Blockchain technology），也被称之为分布式账本技术，是一种互联网数据库技术，其特点是去中心化、公开透明，让每个人均可参与数据库记录。

### Base (基础概念)

- 交易（Transaction）：一次操作，导致账本状态的一次改变，如添加一条记录；
- 区块（Block）：记录一段时间内发生的交易和状态结果，是对当前账本状态的一次共识；
- 链（Chain）：由一个个区块按照发生顺序串联而成，是整个状态变化的日志记录。

> 如果把区块链作为一个状态机，则每次交易就是试图改变一次状态，而每次共识生成的区块，就是参与者对于区块中所有交易内容导致状态改变的结果进行确认。

简单理解就是:

> 如果我们把数据库假设成一本账本，读写数据库就可以看做一种记账的行为，区块链技术的原理就是在一段时间内找出记账最快最好的人，由这个人来记账，然后将账本的这一页信息发给整个系统里的其他所有人。这也就相当于改变数据库所有的记录，发给全网的其他每个节点，所以区块链技术也称为分布式账本（distributed ledger）。

### Vapor (用来开发服务端的Swift框架)

既然要用swift实现 ， 我在这里就选择vapor作为服务端框架来使用 ， vapor里面有意思的东西很多 ， 这里只介绍基本的操作而不深究其原理 。

### Install

前置条件 ， 这里我们使用macOS进行开发部署 ， 以下是需要软件和版本。

- Install Xcode 9.3 or greater from the Mac App Store.
- Vapor requires Swift 4.1 or greater.
- Vapor Toolbox: 3.1.7
- Vapor Framework: 3.0.8
- homeBrew

接着使用homeBrew安装

```bash
brew install vapor/tap/vapor
```

如果一切输出正常的话我们就可以继续啦。

### Get Started

现在vapor已经装好了 ， 我们可以先把基本的准备工作弄好
使用vapor初始化工程

```bash
vapor new blockChainServer
```

生成工程文件

```bash
vapor xcode
```

接着打开 blockChainServer.xcodeproj 文件 ， 在导航上的schema上选择 run ，接着按下 `Command` + `R`
这时你应能够在控制台看到输出的server地址了

## Practice Begin

到现在我们一切准备工作都就绪了 ， 那么开始鼓捣个区块链api出来吧 。

### Base Model

区块链的基本概念上面介绍了，包含以下几类，我们使用oop可以抽象出以下一些class

- Transaction     交易
- Block           区块
- Blockchain      区块链
- BlockChainNode  区块链节点

排列由下向上存在集合关系。 

**其实这里面最后应该加上一个区块网络不过这里我们暂时不需要实现全部网络，这里我们先搭建一个内网环境的来练练手**

下面分别来看下几个model的代码
(ps:这里的框架添加的协议和扩展很多，不在此过多介绍，请把关注点放在class本身)

Transaction.swift

```swift
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
```

这里我们可以看到定义了几个property ， 

- id是SQLiteModel协议需要实现的 ， 这里只要记住是为了数据持久化就好
- to : 交易的接收方
- from : 交易的发起方
- amount : 金额

Block.swift

```swift
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
```

- index : 区块序号
- dateCreated : 创建日期
- previousHash : 前一个区块的哈希值 
- hash : 当前区块的哈希值
- nonce : 先记住和工作量证明有关 
- message : 这里是为了我们看到输出

Blockchain.swift

```swift
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
```

BlockChainNode.swift

```swift
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
```

- address : 节点地址

### Action

这里涉及到的事件主要是计算hash ， 我们在这里面给String 添加一个extension

```swift
extension String {
    func sha1Hash() -> String {
        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = []
        
        let inputPipe = Pipe()
        
        inputPipe.fileHandleForWriting.write(self.data(using: .utf8)!)
        
        inputPipe.fileHandleForWriting.closeFile()
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardInput = inputPipe
        task.launch()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let hash = String(data: data, encoding: .utf8)!
        return hash.replacingOccurrences(of: "  -\n", with: "")
    }
}
```

给date也添加一个便于我们输出区块创建时间

```swift
extension Date {
    func toString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: self)
    }
}
```

### Service

在这里我们把所有对区块链的操作抽象为一个service类

BlockchainService.swift

```swift
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
```

### Controller & Router

这里我们基本完成了所有基本模型的搭建 ， 现在需要对我们的server进行操作 ， 让我们可以方便的通过curl调用我们的区块链系统 。

BlockChainController.swift

```swift
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
```

routes.swift

```swift
import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    let bcc = BlockChainController()
    router.post("block", use: bcc.addBlock)
    router.post("transaction", use: bcc.addTransaction)
    router.get("blockchain", use: bcc.findBlockChain)
    router.post("node", use: bcc.registeNode)
    router.get("node", use: bcc.allNodes)
    router.post("resolve", use: bcc.resolve)
}
```

现在解释一下我们注册的api都是干啥的

ps:API层遵守restfull

- post("block", use: bcc.addBlock) 增加一个区块
- post("transaction", use: bcc.addTransaction) 新增一笔交易
- get("blockchain", use: bcc.findBlockChain) 查询区块链
- post("node", use: bcc.registeNode) 增加节点
- get("node", use: bcc.allNodes) 获取全部节点
- post("resolve", use: bcc.resolve) 解决冲突

### Example

下面我们可以让服务运行起来 ， 然后通过curl命令行来调用区块链系统 ，

#### 编译工程

进入我们的工程目录 ， 执行命令

```bash
vapor build
```

你应能看到以下输出

```bash
Building Project [Done]
```

这说明我们的工程可以运行了

#### 运行工程

```bash
vapor run serve --port=8080
```

我们在本地8080端口上开启我们的服务

这时应能看到如下输出

```bash
Running blockChainServer ...
[ INFO ] Migrating 'sqlite' database (/Users/felix/Documents/TestFolder/blockChainServer/.build/checkouts/fluent.git-6251908308727715749/Sources/Fluent/Migration/MigrationConfig.swift:69)
[ INFO ] Preparing migration 'Todo' (/Users/felix/Documents/TestFolder/blockChainServer/.build/checkouts/fluent.git-6251908308727715749/Sources/Fluent/Migration/Migrations.swift:111)
[ INFO ] Preparing migration 'Block' (/Users/felix/Documents/TestFolder/blockChainServer/.build/checkouts/fluent.git-6251908308727715749/Sources/Fluent/Migration/Migrations.swift:111)
[ INFO ] Preparing migration 'Blockchain' (/Users/felix/Documents/TestFolder/blockChainServer/.build/checkouts/fluent.git-6251908308727715749/Sources/Fluent/Migration/Migrations.swift:111)
[ INFO ] Preparing migration 'BlockChainNode' (/Users/felix/Documents/TestFolder/blockChainServer/.build/checkouts/fluent.git-6251908308727715749/Sources/Fluent/Migration/Migrations.swift:111)
[ INFO ] Migrations complete (/Users/felix/Documents/TestFolder/blockChainServer/.build/checkouts/fluent.git-6251908308727715749/Sources/Fluent/Migration/MigrationConfig.swift:73)
[Deprecated] --option=value syntax is deprecated. Please use --option value (with no =) instead.
Server starting on http://localhost:8080
```

现在我们只要用api调用以下 ， 本机的区块链系统就会响应了 ， 让我们试一下吧

#### 创建区块

```bash
curl -s -X POST localhost:8080/block
```

你会在一段时间后看到响应

```json
{
    "dateCreated": "2018-08-11 17:19:01",
    "hash": "1124aa2a5867abee8b9cc3a3f4051b6665f89e26",
    "id": 1,
    "index": 0,
    "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
    "nonce": 193,
    "previousHash": "0",
    "transactions": []
}
```

我们的第一个block已经创建成功并且被加入区块链里了 ， 他的previousHash为“0”是因为他是创世区块 。

#### 添加交易

我们可以在这里添加几笔交易看看

```bash
curl -s -X POST localhost:8080/transaction --data "from=Felix&to=mayun&amount=100" | python -m json.tool
```

data里面表示 Felix向mayun转账100 每次添加后你将会得到区块的最新信息

```json
{
    "dateCreated": "2018-08-11 17:19:01",
    "hash": "1124aa2a5867abee8b9cc3a3f4051b6665f89e26",
    "id": 1,
    "index": 0,
    "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
    "nonce": 193,
    "previousHash": "0",
    "transactions": [
        {
            "amount": 100,
            "from": "Felix",
            "to": "mayun"
        }
    ]
}
```

#### 查询链

我们可以重复以上操作几次,然后查看整个区块链信息

```bash
curl -s -X GET localhost:8080/blockchain | python -m json.tool
```

会看到如下输出

```json
{
    "blocks": [
        {
            "dateCreated": "2018-08-11 17:19:01",
            "hash": "1124aa2a5867abee8b9cc3a3f4051b6665f89e26",
            "id": 1,
            "index": 0,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 193,
            "previousHash": "0",
            "transactions": [
                {
                    "amount": 100,
                    "from": "Felix",
                    "to": "mayun"
                },
                {
                    "amount": 100,
                    "from": "Felix",
                    "to": "mayun"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:27:39",
            "hash": "11bec5f7bf8226c62119adfbb03ad37d24267092",
            "id": 2,
            "index": 1,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 277,
            "previousHash": "1124aa2a5867abee8b9cc3a3f4051b6665f89e26",
            "transactions": [
                {
                    "amount": 100,
                    "from": "Felix",
                    "to": "mayun"
                },
                {
                    "amount": 100,
                    "from": "Felix",
                    "to": "mayun"
                }
            ]
        }
    ],
    "id": 1
}
```

我们可以看到Felix不停的向mayun转100块 ， 真不要脸 。

#### 节点以及解决冲突

区块链同时存在与多个主机上,也就是说会有很多的block-chain-server运行,而对于不同的运算会有多个解产生,这就是冲突问题了,那么我们看下冲突解决的过程

- 首先,我们在8081端口同时开启一个服务

```bash
vapor run serve --port=8081
```

- 然后添加几个区块和交易,因为我们要验证解决冲突,所以应该比运行在8080端口上的区块多。


```bash
curl -s -X POST localhost:8081/block | python -m json.tool
```

- 重复几次操作 ， 最后看下8081伤的blockchain

```json
{
    "blocks": [
        {
            "dateCreated": "2018-08-11 17:35:15",
            "hash": "1152cb1aac50abd803a4589f28c7e054db207e23",
            "id": 1,
            "index": 0,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 215,
            "previousHash": "0",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:37:18",
            "hash": "1127f8c712ae3205ccbab9788392bcd190b8b6b1",
            "id": 2,
            "index": 1,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 380,
            "previousHash": "1152cb1aac50abd803a4589f28c7e054db207e23",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:37:39",
            "hash": "11b5d293c3068081f1771f14f96a3e450f282171",
            "id": 3,
            "index": 2,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 64,
            "previousHash": "1127f8c712ae3205ccbab9788392bcd190b8b6b1",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:37:45",
            "hash": "11d97dfca7cc7a67c22b9df06017768fca0a193f",
            "id": 4,
            "index": 3,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 125,
            "previousHash": "11b5d293c3068081f1771f14f96a3e450f282171",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:38:03",
            "hash": "115a991bd5d2ebe6e232b421965ab852b97a4202",
            "id": 5,
            "index": 4,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 220,
            "previousHash": "11d97dfca7cc7a67c22b9df06017768fca0a193f",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        }
    ],
    "id": 1
}
```

- 然后我们要让8080知道有这么一个节点

```bash
curl -s -X POST localhost:8080/node --data "address=localhost:8081" | python -m json.tool
```

- 我们会看到节点已经注册成功了

```bash
{
    "address": "localhost:8081",
    "id": 1
}
```

- 这时我们让8080去主动解决冲突

```bash
curl -s -X POST localhost:8080/resolve | python -m json.tool
```

- 再查看8080上的区块链,发现已经被替换为较长的8081上的blocks了。

```json
{
    "blocks": [
        {
            "dateCreated": "2018-08-11 17:35:15",
            "hash": "1152cb1aac50abd803a4589f28c7e054db207e23",
            "id": 1,
            "index": 0,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 215,
            "previousHash": "0",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:37:18",
            "hash": "1127f8c712ae3205ccbab9788392bcd190b8b6b1",
            "id": 2,
            "index": 1,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 380,
            "previousHash": "1152cb1aac50abd803a4589f28c7e054db207e23",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:37:39",
            "hash": "11b5d293c3068081f1771f14f96a3e450f282171",
            "id": 3,
            "index": 2,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 64,
            "previousHash": "1127f8c712ae3205ccbab9788392bcd190b8b6b1",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:37:45",
            "hash": "11d97dfca7cc7a67c22b9df06017768fca0a193f",
            "id": 4,
            "index": 3,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 125,
            "previousHash": "11b5d293c3068081f1771f14f96a3e450f282171",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        },
        {
            "dateCreated": "2018-08-11 17:38:03",
            "hash": "115a991bd5d2ebe6e232b421965ab852b97a4202",
            "id": 5,
            "index": 4,
            "message": "\u6b64\u533a\u5757\u5df2\u6dfb\u52a0\u81f3\u533a\u5757\u94fe",
            "nonce": 220,
            "previousHash": "11d97dfca7cc7a67c22b9df06017768fca0a193f",
            "transactions": [
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                },
                {
                    "amount": 200,
                    "from": "mayun",
                    "to": "Felix"
                }
            ]
        }
    ],
    "id": 1
}
```

### Summary

可以看到大概区块链的设计还是比较有意思的，细节部分请不要在意（比如sha1和prefix“11” 😄）
基本的介绍就到这里，建议自己动手实践一遍，还是蛮有意思的。