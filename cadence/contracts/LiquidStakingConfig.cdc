/**

# Liquid staking config

# Author: Increment Labs

*/

import FlowIDTableStaking from "./flow/FlowIDTableStaking.cdc"

pub contract LiquidStakingConfig {

    /// Minmum limit of staking
	pub var minStakingAmount: UFix64

    /// Pauses
    pub var isStakingPaused: Bool
    pub var isUnstakingPaused: Bool
    pub var isMigratingPaused: Bool

    /// Max staking amount
    pub var stakingCap: UFix64
    
    // Windows size before auction stage end, left for bots to handle unstaking requests
    pub var windowSizeBeforeStakingEnd: UInt64

    /// Fee of quick unstaking from reserved committed vault
    pub var quickUnstakeFee: UFix64
    /// Fee of each epoch reward
    pub var rewardFee: UFix64
	
    // events
    pub event ConfigMinStakingAmount(newValue: UFix64, oldValue: UFix64)
    pub event ConfigStakingCap(newValue: UFix64, oldValue: UFix64)
    pub event ConfigStakingPause(newValue: Bool, oldValue: Bool)
    pub event ConfigUnstakingPause(newValue: Bool, oldValue: Bool)
    pub event ConfigMigratingPause(newValue: Bool, oldValue: Bool)
    pub event ConfigQuickUnstakeFee(newValue: UFix64, oldValue: UFix64)
    pub event ConfigRewardFee(newValue: UFix64, oldValue: UFix64)
    pub event ConfigWindowSize(newValue: UInt64, oldValue: UInt64)

    /// Reserved parameter fields: {ParamName: Value}
    access(self) let _reservedFields: {String: AnyStruct}

    pub fun calcStakedPayout(stakedAmount: UFix64): UFix64 {
		let systemTotalStaked = FlowIDTableStaking.getTotalStaked()
		let epochTokenPayout = FlowIDTableStaking.getEpochTokenPayout()

        if systemTotalStaked == 0.0 {
            return 0.0
        }

		let rewardScale = epochTokenPayout / systemTotalStaked
		var rewardAmount = stakedAmount * rewardScale
		let nodeCutAmount = rewardAmount * FlowIDTableStaking.getRewardCutPercentage()

		rewardAmount = rewardAmount - nodeCutAmount

        let protocolCutAmount = rewardAmount * self.rewardFee
        rewardAmount = rewardAmount - protocolCutAmount

		return rewardAmount	
	}

    /// Config Admin
    ///
    pub resource Admin {

		pub fun setMinStakingAmount(minStakingAmount: UFix64) {
            emit ConfigMinStakingAmount(newValue: minStakingAmount, oldValue: LiquidStakingConfig.minStakingAmount)
			LiquidStakingConfig.minStakingAmount = minStakingAmount
		}

        pub fun setStakingCap(stakingCap: UFix64) {
            emit ConfigStakingCap(newValue: stakingCap, oldValue: LiquidStakingConfig.stakingCap)
			LiquidStakingConfig.stakingCap = stakingCap
		}

        pub fun setQuickUnstakeFee(quickUnstakeFee: UFix64) {
            pre {
                quickUnstakeFee < 1.0: "Invalid quick unstake fee"
            }
            emit ConfigQuickUnstakeFee(newValue: quickUnstakeFee, oldValue: LiquidStakingConfig.quickUnstakeFee)
            LiquidStakingConfig.quickUnstakeFee = quickUnstakeFee
        }

        pub fun setRewardFee(rewardFee: UFix64) {
            pre {
                rewardFee < 1.0: "Invalid reward fee"
            }
            emit ConfigRewardFee(newValue: rewardFee, oldValue: LiquidStakingConfig.quickUnstakeFee)
            LiquidStakingConfig.rewardFee = rewardFee
        }

        pub fun setPause(stakingPause: Bool, unstakingPause: Bool, migratingPause: Bool) {
            if LiquidStakingConfig.isStakingPaused != stakingPause {
                emit ConfigStakingPause(newValue: stakingPause, oldValue: LiquidStakingConfig.isStakingPaused)
                LiquidStakingConfig.isStakingPaused = stakingPause
            }

            if LiquidStakingConfig.isUnstakingPaused != unstakingPause {
                emit ConfigUnstakingPause(newValue: unstakingPause, oldValue: LiquidStakingConfig.isUnstakingPaused)
                LiquidStakingConfig.isUnstakingPaused = unstakingPause
            }
            if LiquidStakingConfig.isMigratingPaused != migratingPause {
                emit ConfigStakingPause(newValue: migratingPause, oldValue: LiquidStakingConfig.isMigratingPaused)
                LiquidStakingConfig.isMigratingPaused = migratingPause
            }
        }

        pub fun setWindowSize(windowSize: UInt64) {
            emit ConfigWindowSize(newValue: windowSize, oldValue: LiquidStakingConfig.windowSizeBeforeStakingEnd)
            LiquidStakingConfig.windowSizeBeforeStakingEnd = windowSize
        }
	}


    init() {
        self.minStakingAmount = 0.1
        self.stakingCap = 500.0
        self.quickUnstakeFee = 0.003
        self.rewardFee = 0.1
        self.windowSizeBeforeStakingEnd = 2500  // 2500 block views, about 1 hour


        self.isStakingPaused = false
        self.isUnstakingPaused = false
        self.isMigratingPaused = false
        
        self._reservedFields = {}

        self.account.save(<-create Admin(), to: /storage/liquidStakingConfigAdmin)
    }
}