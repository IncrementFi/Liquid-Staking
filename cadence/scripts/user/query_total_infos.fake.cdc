import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"
import FlowEpoch from "../../contracts/flow/FlowEpoch.cdc"

pub fun main(userAddr: Address?): {String: AnyStruct} {
    

    var voucherInfos: [AnyStruct]? = nil
    var migratedInfos: [AnyStruct]? = nil
    return {
        "CurrentEpoch": FlowEpoch.currentEpochCounter,
        "CurrentUnstakeEpoch": FlowEpoch.currentEpochCounter + 1,

        "stFlowFlow": 1.0015,
        "FlowStFlow": 0.9985,
        "FlowUSD": 2.4,
        "TotalStaked": 9998.0,
        "APR": 0.08,  // 这是APR，前端显示APY =  (1+0.08/356)^356 - 1 = 0.085

        "EpochMetadata": {
            "StartView": 1000,
            "StartTimestamp": 128312.0,
            "EndView": 1200,
            "CurrentView": 1145,
            "CurrentTimestamp": 123212.0,
            "StakingEndView": 1190
        },
        "User": {
            "UnstakingVouchers": [
                {
                    "uuid": 0,
                    "lockedFlowAmount": 12.123,
                    "unlockEpoch": FlowEpoch.currentEpochCounter + 1
                },
                {
                    "uuid": 1,
                    "lockedFlowAmount": 1241.212,
                    "unlockEpoch": FlowEpoch.currentEpochCounter
                }
            ],
            "MigratedInfos": {
                "lockedTokensUsed": 90.0,
                "unlockedTokensUsed": 83.0,
                "migratedInfos": [
                    {
                        "tokensCommitted": 10.0,
                        "tokensStaked": 10.0,
                        "tokensUnstaking": 10.0,
                        "tokensRewarded": 10.0,
                        "tokensUnstaked": 10.0,
                        "tokensRequestedToUnstake": 10.0
                    }
                ]
            }
        }
    }
}