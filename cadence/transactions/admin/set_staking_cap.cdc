import LiquidStakingConfig from "../../contracts/LiquidStakingConfig.cdc"

transaction(newCap: UFix64) {
    prepare(signer: AuthAccount) {
        let adminRef = signer.borrow<&LiquidStakingConfig.Admin>(from: LiquidStakingConfig.adminPath)!
        adminRef.setStakingCap(stakingCap: newCap)
    }
}