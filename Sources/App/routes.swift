import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        return "Hello, world!"
    }

    // Example of configuring a controller
    let todoController = TodoController()
    router.get("todos", use: todoController.index)
    router.post("todos", use: todoController.create)
    router.delete("todos", Todo.parameter, use: todoController.delete)
    
    
    let bcc = BlockChainController()
    router.post("block", use: bcc.addBlock)
    router.post("transaction", use: bcc.addTransaction)
    router.get("blockchain", use: bcc.findBlockChain)
    router.post("node", use: bcc.registeNode)
    router.get("node", use: bcc.allNodes)
    router.post("resolve", use: bcc.resolve)
//    resolve
}
