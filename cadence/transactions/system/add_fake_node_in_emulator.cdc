import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"


transaction() {

    prepare(nodeAcct: AuthAccount) {
        let vaultRef = nodeAcct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!

        let flowVault1 <- vaultRef.withdraw(amount: 250000.0)
        let nodeStaker1 <- FlowIDTableStaking.addNodeRecord(
            id: "node-1-1",
            role: 1,
            networkingAddress: "execution-001.devnet36.nodes.onflow.org:3569",
            networkingKey: "node-1-1-networkingKey",
            stakingKey: "node-1-1-stakingKey",
            tokensCommitted: <-flowVault1
        )
        nodeAcct.save(<-nodeStaker1, to: /storage/nodeStaker1)

        let flowVault2 <- vaultRef.withdraw(amount: 250000.0)
        let nodeStaker2 <- FlowIDTableStaking.addNodeRecord(
            id: "node-1-2",
            role: 1,
            networkingAddress: "collection-002.devnet36.nodes.onflow.org:3569",
            networkingKey: "node-1-2-networkingKey",
            stakingKey: "node-1-2-stakingKey",
            tokensCommitted: <-flowVault2
        )
        nodeAcct.save(<-nodeStaker2, to: /storage/nodeStaker2)

        let flowVault3 <- vaultRef.withdraw(amount: 250000.0)
        let nodeStaker3 <- FlowIDTableStaking.addNodeRecord(
            id: "node-1-3",
            role: 1,
            networkingAddress: "execution-002.devnet36.nodes.onflow.org:3569",
            networkingKey: "node-1-3-networkingKey",
            stakingKey: "node-1-3-stakingKey",
            tokensCommitted: <-flowVault3
        )
        nodeAcct.save(<-nodeStaker3, to: /storage/nodeStaker3)

        let flowVault4 <- vaultRef.withdraw(amount: 250000.0)
        let nodeStaker4 <- FlowIDTableStaking.addNodeRecord(
            id: "node-1-4",
            role: 1,
            networkingAddress: "collection-004.devnet36.nodes.onflow.org:3569",
            networkingKey: "node-1-4-networkingKey",
            stakingKey: "node-1-4-stakingKey",
            tokensCommitted: <-flowVault4
        )
        nodeAcct.save(<-nodeStaker4, to: /storage/nodeStaker4)

        let flowVault5 <- vaultRef.withdraw(amount: 250000.0)
        let nodeStaker5 <- FlowIDTableStaking.addNodeRecord(
            id: "node-1-5",
            role: 1,
            networkingAddress: "collection-005.devnet36.nodes.onflow.org:3569",
            networkingKey: "node-1-5-networkingKey",
            stakingKey: "node-1-5-stakingKey",
            tokensCommitted: <-flowVault5
        )
        nodeAcct.save(<-nodeStaker5, to: /storage/nodeStaker5)
    }
}