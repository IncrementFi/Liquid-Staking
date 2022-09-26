import LiquidStaking from "../../contracts/LiquidStaking.cdc"
import stFlowToken from "../../contracts/stFlowToken.cdc"
import FlowToken from "../../contracts/standard/FlowToken.cdc"
import FungibleToken from "../../contracts/standard/FungibleToken.cdc"

transaction(flowAmount: UFix64) {
    prepare(userAccount: AuthAccount) {
        destroy userAccount.load<@AnyResource>(from: stFlowToken.tokenVaultPath)
        destroy userAccount.load<@AnyResource>(from: LiquidStaking.WithdrawVoucherCollectionPath)
    }
}