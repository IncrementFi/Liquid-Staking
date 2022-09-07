/**

# Liquid Staking

# Author: Increment Labs

*/

import FlowToken from "./standard/FlowToken.cdc"

import FlowIDTableStaking from "./flow/FlowIDTableStaking.cdc"
import FlowEpoch from "./flow/FlowEpoch.cdc"

import stFlowToken from "./stFlowToken.cdc"
import LiquidStakingConfig from "./LiquidStakingConfig.cdc"
import DelegatorManager from "./DelegatorManager.cdc"

pub contract LiquidStaking {

    /// Paths
    pub var UnstakingVoucherCollectionPath: StoragePath
    pub var UnstakingVoucherCollectionPublicPath: PublicPath

    /// Events
    pub event Stake(flowAmountIn: UFix64, stFlowAmountOut: UFix64, epoch: UInt64)
    pub event UnstakeSlowly(stFlowAmountIn: UFix64, lockedFlowAmount: UFix64, epoch: UInt64, unlockEpoch: UInt64, voucherUUID: UInt64)
    pub event UnstakeQuickly(stFlowAmountIn: UFix64, flowAmountOut: UFix64, epoch: UInt64)
    pub event MigrateDelegator(uuid: UInt64, migratedFlowIn: UFix64, stFlowOut: UFix64)
    pub event BurnUnstakingVoucher(uuid: UInt64, cashingFlowAmount: UFix64, cashingEpoch: UInt64)

    /// Reserved parameter fields: {ParamName: Value}
    access(self) let _reservedFields: {String: AnyStruct}

    /// UnstakingVoucher
    ///
    /// Voucher for unstaking certificate, has an inner locking period up to two epoch
    ///
    pub resource UnstakingVoucher {

        /// Flow token amount to be unlocked
        pub let lockedFlowAmount: UFix64

        /// Unlock epoch
        pub let unlockEpoch: UInt64

        init(lockedFlowAmount: UFix64, unlockEpoch: UInt64) {
            self.lockedFlowAmount = lockedFlowAmount
            self.unlockEpoch = unlockEpoch
        }
    }

    /// Stake
    ///
    /// FlowToken -> stFlowToken
    ///
    pub fun stake(flowVault: @FlowToken.Vault): @stFlowToken.Vault {
        pre {
            // Min staking amount check
            flowVault.balance > LiquidStakingConfig.minStakingAmount: "Stake amount must be greater than ".concat(LiquidStakingConfig.minStakingAmount.toString())
            // Staking amount cap check
            LiquidStakingConfig.stakingCap >= flowVault.balance + DelegatorManager.getTotalValidStakingAmount(): "Exceed stake cap"
            // Pause check
            LiquidStakingConfig.isStakingPaused == false: "Staking is paused"
            // Flow blockchain staking state check
            FlowIDTableStaking.stakingEnabled(): "The Flow blockchain currently pauses the staking operation."
            // Protocol staking state check
            FlowEpoch.currentEpochCounter == DelegatorManager.quoteEpochCounter: "Please wait thef protocol to enter the new staking epoch"
        }

        let flowAmountToStake = flowVault.balance
        let stFlowAmountToMint = self.calcStFlowFromFlow(flowAmount: flowAmountToStake)
        
        //
        DelegatorManager.depositToCommitted(flowVault: <-flowVault)

        // Mint stFlow
        let stFlowVault <- stFlowToken.mintTokens(amount: stFlowAmountToMint)

        emit Stake(flowAmountIn: flowAmountToStake, stFlowAmountOut: stFlowAmountToMint, epoch: FlowEpoch.currentEpochCounter)

        return <-stFlowVault
    }

    /// Unstake Slowly
    ///
    /// stFlowToken -> UnstakingVoucher
    ///
    pub fun unstakeSlowly(stFlowVault: @stFlowToken.Vault): @UnstakingVoucher {
        pre {
            // Pause check
            LiquidStakingConfig.isUnstakingPaused == false: "Unstaking is paused"
        }
        let stFlowAmountToBurn = stFlowVault.balance
        let flowAmountToUnstake = self.calcFlowFromStFlow(stFlowAmount: stFlowAmountToBurn)

        // Burn stFlow
        stFlowToken.burnTokens(from: <-stFlowVault)

        //
        DelegatorManager.requestWithdrawFromStaked(amount: flowAmountToUnstake)
        
        let currentBlockView = getCurrentBlock().view
        let stakingEndView = FlowEpoch.getEpochMetadata(FlowEpoch.currentEpochCounter)!.stakingEndView

        var unlockEpoch = FlowEpoch.currentEpochCounter + 2
        if FlowIDTableStaking.stakingEnabled() {
            // Before flowchain ends staking, a window of processing time needs to be reserved for the bots.
            if currentBlockView + LiquidStakingConfig.windowSizeBeforeStakingEnd >= stakingEndView {
                unlockEpoch = FlowEpoch.currentEpochCounter + 3
            }
        } else {
            // During Flowchain stops staking, all unstaking requests will be reserved until the next epoch for future processing.
            unlockEpoch = FlowEpoch.currentEpochCounter + 3
        }
        
        let unstakeVoucher <- create UnstakingVoucher(
            lockedFlowAmount: flowAmountToUnstake,
            unlockEpoch: unlockEpoch
        )

        emit UnstakeSlowly(stFlowAmountIn: stFlowAmountToBurn, lockedFlowAmount: flowAmountToUnstake, epoch: FlowEpoch.currentEpochCounter, unlockEpoch: unlockEpoch, voucherUUID: unstakeVoucher.uuid)

        return <- unstakeVoucher
    }

    /// Unstake Quickly
    ///
    /// Fast unstake from reserved committed tokens
    /// stFlowToken -> FlowToken
    ///
    pub fun unstakeQuickly(stFlowVault: @stFlowToken.Vault): @FlowToken.Vault {
        pre {
             // Flow chain unstaking state check
            FlowIDTableStaking.stakingEnabled(): "The Flow blockchain currently pauses the unstaking operation."
            // Pause check
            LiquidStakingConfig.isUnstakingPaused == false: "Unstaking is paused"
            // Protocol unstaking state check
            FlowEpoch.currentEpochCounter == DelegatorManager.quoteEpochCounter: "Please wait the protocol to enter the new staking epoch"
        }
        let stFlowAmountToBurn = stFlowVault.balance
        let flowAmountToUnstake = self.calcFlowFromStFlow(stFlowAmount: stFlowAmountToBurn)

        //
        let flowVault <- DelegatorManager.withdrawFromCommitted(amount: flowAmountToUnstake)
        
        // Fast unstake fee
        let feeVault <- flowVault.withdraw(amount: LiquidStakingConfig.quickUnstakeFee * flowAmountToUnstake)
        DelegatorManager.depositProtocolReservedVault(flowVault: <-feeVault, purpose: "unstake fee")
        
        // Burn stFlow
        stFlowToken.burnTokens(from: <-stFlowVault)

        emit UnstakeQuickly(stFlowAmountIn: stFlowAmountToBurn, flowAmountOut: flowVault.balance, epoch: FlowEpoch.currentEpochCounter)
        
        return <-flowVault
    }

    /// Unstaking Voucher Cashing
    ///
    /// UnstakingVoucher -> FlowToken
    ///
    pub fun cashingUnstakingVoucher(voucher: @UnstakingVoucher): @FlowToken.Vault {
        pre {
            // Waiting all unstaked tokens to be collected
            DelegatorManager.quoteEpochCounter >= voucher.unlockEpoch: "The cashing day hasn't arrived yet"
        }
        
        let cashingFlowAmount = voucher.lockedFlowAmount
        
        let flowVault <-DelegatorManager.withdrawFromUnstaked(amount: cashingFlowAmount)

        emit BurnUnstakingVoucher(uuid: voucher.uuid, cashingFlowAmount: cashingFlowAmount, cashingEpoch: DelegatorManager.quoteEpochCounter)

        // Burn voucher
        destroy voucher

        return <-flowVault
    }

    /// Migrate delegator
    ///
    /// NodeDelegator -> stFlow
    ///
    pub fun migrate(delegator: @FlowIDTableStaking.NodeDelegator): @stFlowToken.Vault {
        pre {
            // Flowchain staking state check
            FlowIDTableStaking.stakingEnabled(): "System staking disabled"
            // Pause check
            LiquidStakingConfig.isMigratingPaused == false: "Migrating is paused"
            // Protocol staking state check
            FlowEpoch.currentEpochCounter == DelegatorManager.quoteEpochCounter: "Please wait the protocol to enter the new staking epoch"
        }
        let delegatroInfo = FlowIDTableStaking.DelegatorInfo(nodeID: delegator.nodeID, delegatorID: delegator.id)
        
        assert(LiquidStakingConfig.stakingCap >= delegatroInfo.tokensStaked + DelegatorManager.getTotalValidStakingAmount(), message: "Exceed stake cap")
        assert(delegatroInfo.tokensUnstaking == 0.0, message: "Wait for the previous unstaking processing to complete")
        assert(delegatroInfo.tokensRewarded == 0.0, message: "Please claim the reward before migrating")
        assert(delegatroInfo.tokensUnstaked == 0.0, message: "Please withdraw the unstaked tokens before migrating")
        assert(delegatroInfo.tokensRequestedToUnstake == 0.0, message: "Please cancel the unstake requests before migrating")
        assert(delegatroInfo.tokensCommitted == 0.0, message: "Please cancel the stake requests before migrating")
        assert(delegatroInfo.tokensStaked > 0.0, message: "No staked tokens need to be migrated.")

        let stakedFlowToMigrate = delegatroInfo.tokensStaked

        //
        let stFlowAmountToMint = self.calcStFlowFromFlow(flowAmount: stakedFlowToMigrate)

        emit MigrateDelegator(uuid: delegator.uuid, migratedFlowIn: stakedFlowToMigrate, stFlowOut: stFlowAmountToMint)

        DelegatorManager.migrateDelegator(delegator: <-delegator)

        // Mint stFlow
        let stFlowVault <- stFlowToken.mintTokens(amount: stFlowAmountToMint)
        return <-stFlowVault
    }



    /// Unstaking voucher collection
    ///
    pub resource interface UnstakingVoucherCollectionPublic {
        pub fun getVoucherInfos(): [AnyStruct]
        pub fun deposit(voucher: @UnstakingVoucher)
    }
    pub resource UnstakingVoucherCollection: UnstakingVoucherCollectionPublic {
        /// Unstaking voucher list 
        access(self) var vouchers: @[UnstakingVoucher]

        destroy() {
            destroy self.vouchers
        }

        pub fun deposit(voucher: @UnstakingVoucher) {
            self.vouchers.append(<-voucher)
        }

        pub fun withdraw(uuid: UInt64): @UnstakingVoucher {
            var findIndex: Int? = nil
            var index = 0
            while index < self.vouchers.length {
                if self.vouchers[index].uuid == uuid {
                    findIndex = index
                    break
                }
                index = index + 1
            }

            assert(findIndex != nil, message: "Cannot find voucher with uuid ".concat(uuid.toString()))
            return <-self.vouchers.remove(at: findIndex!)
        }

        pub fun getVoucherInfos(): [AnyStruct] {
            var voucherInfos: [AnyStruct] = []
            var index = 0
            while index < self.vouchers.length {
                voucherInfos.append({
                    "uuid": self.vouchers[index].uuid,
                    "lockedFlowAmount": self.vouchers[index].lockedFlowAmount,
                    "unlockEpoch": self.vouchers[index].unlockEpoch
                })
                index = index + 1
            }
            return voucherInfos
        }
        init() {
            self.vouchers <- []
        }
    }

    pub fun createEmptyUnstakingVoucherCollection(): @UnstakingVoucherCollection {
        return <-create UnstakingVoucherCollection()
    }
    
    /// Calculate exchange amount from Flow to stFlow
    ///
    pub fun calcStFlowFromFlow(flowAmount: UFix64): UFix64 {
        let currentEpochSnapshot = DelegatorManager.borrowEpochSnapshot(at: DelegatorManager.quoteEpochCounter)
        let flowPrice = currentEpochSnapshot.quoteFlowStFlow
        
        let stFlowAmount = flowPrice * flowAmount
        return stFlowAmount
    }

    /// Calculate exchange amount from stFlow to Flow
    ///
    pub fun calcFlowFromStFlow(stFlowAmount: UFix64): UFix64 {
        let currentEpochSnapshot = DelegatorManager.borrowEpochSnapshot(at: DelegatorManager.quoteEpochCounter)
        let stFlowPrice = currentEpochSnapshot.quoteStFlowFlow

        let flowAmount = stFlowPrice * stFlowAmount
        return flowAmount
    }

    init() {
        self.UnstakingVoucherCollectionPath = /storage/unstaking_voucher_collection
        self.UnstakingVoucherCollectionPublicPath = /public/unstaking_voucher_collection
        self._reservedFields = {}
    }
}
 