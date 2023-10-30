import LiquidStakingConfig from "../../contracts/LiquidStakingConfig.cdc"

transaction(newProtocolCut: UFix64) {
    prepare(signer: AuthAccount) {
        let adminRef = signer.borrow<&LiquidStakingConfig.Admin>(from: LiquidStakingConfig.adminPath)
            ?? panic("cannot borrow reference to Liquid Staking Admin")
        adminRef.setProtocolFee(protocolFee: newProtocolCut)
    }
}