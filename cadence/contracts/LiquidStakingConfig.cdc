/**

# Liquid staking config

# Author: Increment Labs

*/

import FlowIDTableStaking from "./standard/emulator/FlowIDTableStaking.cdc"

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

    /// Scale factor applied to fixed point number calculation.
    /// Note: The use of scale factor is due to fixed point number in cadence is only precise to 1e-8:
    /// https://docs.onflow.org/cadence/language/values-and-types/#fixed-point-numbers
    pub let scaleFactor: UInt256

    /// 100_000_000.0, i.e. 1.0e8
    pub let ufixScale: UFix64
    
    /// Cut of staking interests reserved as protocol fees
    pub var protocolFee: UFix64
    
    // events
    pub event ConfigMinStakingAmount(newValue: UFix64, oldValue: UFix64)
    pub event ConfigStakingCap(newValue: UFix64, oldValue: UFix64)
    pub event ConfigStakingPause(newValue: Bool, oldValue: Bool)
    pub event ConfigUnstakingPause(newValue: Bool, oldValue: Bool)
    pub event ConfigMigratingPause(newValue: Bool, oldValue: Bool)
    pub event ConfigQuickUnstakeFee(newValue: UFix64, oldValue: UFix64)
    pub event ConfigProtocolFee(newValue: UFix64, oldValue: UFix64)
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

        let protocolCutAmount = rewardAmount * self.protocolFee
        rewardAmount = rewardAmount - protocolCutAmount

        return rewardAmount    
    }

    /// Utility function to convert a UFix64 number to its scaled equivalent in UInt256 format
    /// e.g. 184467440737.09551615 (UFix64.max) => 184467440737095516150000000000
    ///
    pub fun UFix64ToScaledUInt256(_ f: UFix64): UInt256 {
        let integral = UInt256(f)
        let fractional = f % 1.0
        let ufixScaledInteger =  integral * UInt256(self.ufixScale) + UInt256(fractional * self.ufixScale)
        return ufixScaledInteger * self.scaleFactor / UInt256(self.ufixScale)
    }
    
    /// Utility function to convert a fixed point number in form of scaled UInt256 back to UFix64 format
    /// e.g. 184467440737095516150000000000 => 184467440737.09551615
    ///
    pub fun ScaledUInt256ToUFix64(_ scaled: UInt256): UFix64 {
        let integral = scaled / self.scaleFactor
        let ufixScaledFractional = (scaled % self.scaleFactor) * UInt256(self.ufixScale) / self.scaleFactor
        return UFix64(integral) + (UFix64(ufixScaledFractional) / self.ufixScale)
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

        pub fun setProtocolFee(protocolFee: UFix64) {
            pre {
                protocolFee < 1.0: "Invalid protocol fee"
            }
            emit ConfigProtocolFee(newValue: protocolFee, oldValue: LiquidStakingConfig.protocolFee)
            LiquidStakingConfig.protocolFee = protocolFee
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
        self.stakingCap = 100_000.0
        self.quickUnstakeFee = 0.003
        self.protocolFee = 0.1
        self.windowSizeBeforeStakingEnd = 2500  // 2500 block views, about 1 hour

        self.isStakingPaused = false
        self.isUnstakingPaused = false
        self.isMigratingPaused = false

        /// 1e18
        self.scaleFactor = 1_000_000_000_000_000_000
        /// 1.0e8
        self.ufixScale = 100_000_000.0
        
        self._reservedFields = {}

        self.account.save(<-create Admin(), to: /storage/liquidStakingConfigAdmin)
    }
}