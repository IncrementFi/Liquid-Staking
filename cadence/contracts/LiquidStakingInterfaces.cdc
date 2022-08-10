/**

# LiquidStaking related interface definitions all-in-one

# Author: Increment Labs

*/
pub contract interface LiquidStakingInterfaces {

    pub resource interface LiquidStakingPublic {
        pub fun getCurrentEpoch(): UInt64
        pub fun getRewardIndex(epoch: UInt64): UFix64
        pub fun getCurrentRewardIndex(epoch: UInt64): UFix64
        pub fun getEpochToCommitStaking(): UInt64
    }

}