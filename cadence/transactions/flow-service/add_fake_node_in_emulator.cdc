import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"


transaction() {

    prepare(nodeAcct: AuthAccount) {
        let vaultRef = nodeAcct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!

        let flowVault1 <- vaultRef.withdraw(amount: 1260000.0)
        let nodeStaker1 <- FlowIDTableStaking.addNodeRecord(
            id: "execute-node-1",
            role: 3,
            networkingAddress: "execution-001.devnet36.nodes.onflow.org:3569",
            networkingKey: "execute-node-1-networkingKey",
            stakingKey: "execute-node-1-stakingKey",
            tokensCommitted: <-flowVault1
        )
        nodeAcct.save(<-nodeStaker1, to: /storage/nodeStaker1)

        let flowVault2 <- vaultRef.withdraw(amount: 1260000.0)
        let nodeStaker2 <- FlowIDTableStaking.addNodeRecord(
            id: "collection-node-1",
            role: 1,
            networkingAddress: "collection-001.devnet36.nodes.onflow.org:3569",
            networkingKey: "collection-node-1-networkingKey",
            stakingKey: "collection-node-1-stakingKey",
            tokensCommitted: <-flowVault2
        )
        nodeAcct.save(<-nodeStaker2, to: /storage/nodeStaker2)

        let flowVault3 <- vaultRef.withdraw(amount: 1260000.0)
        let nodeStaker3 <- FlowIDTableStaking.addNodeRecord(
            id: "execute-node-2",
            role: 3,
            networkingAddress: "execution-002.devnet36.nodes.onflow.org:3569",
            networkingKey: "execute-node-2-networkingKey",
            stakingKey: "execute-node-2-stakingKey",
            tokensCommitted: <-flowVault3
        )
        nodeAcct.save(<-nodeStaker3, to: /storage/nodeStaker3)
    }
}