/**

# Staking delegators management for liquid staking

# Author: Increment Labs

*/

import FlowToken from "./standard/FlowToken.cdc"
import FungibleToken from "./standard/FungibleToken.cdc"

import FlowIDTableStaking from "./standard/emulator/FlowIDTableStaking.cdc"
import FlowEpoch from "./standard/emulator/FlowEpoch.cdc"

import stFlowToken from "./stFlowToken.cdc"
import LiquidStakingConfig from "./LiquidStakingConfig.cdc"
import LiquidStakingError from "./LiquidStakingError.cdc"

pub contract DelegatorManager {

    /// All delegators managed by liquid staking protocol
    /// {delegator uuid -> NodeDelegator}
    access(self) let allDelegators: @{UInt64: FlowIDTableStaking.NodeDelegator}

    /// Approved Node ID list
    /// {nodeID -> weight}
    pub var approvedNodeIDList: {String: UFix64}
    
    /// Delegator IDs for each node ID
    /// {nodeID -> delegator uuid}
    access(self) let approvedDelegatorIDs: {String: UInt64}

    /// IDs of migrated delegators on each node ID
    // {nodeID -> {delegatorID -> uuid}}
    access(self) let migratedDelegatorIDs: {String: {UInt32: UInt64}}
    
    /// The epoch of latest stFlow's quote
    /// When a new flowchain epoch starts, the new quote epoch will only be started after all rewards 
    /// are collected and the price of stFlow is calculated correctly.
    pub var quoteEpochCounter: UInt64

    /// The default node ID for staking
    /// All new committed tokens will be temporarily stored in this node's delegator
    /// Strategy bots will transfer these committed tokens to other nodes' delegators before staking end
    pub var reservedNodeIDToStake: String

    /// All unstaking requests are temporarily recorded in this reserved value
    /// Strategy bots will handle these unstaking requests to deleagtors
    pub var reservedRequestedToUnstakeAmount: UFix64

    /// Collect and aggregate all rewards & unstaked tokens from all delegators at the beginning of each epoch
    access(self) let totalRewardedVault: @FlowToken.Vault
    access(self) let totalUnstakedVault: @FlowToken.Vault

    /// All epoch snapshot history
    /// {epoch idnex -> snapshot}
    pub var epochSnapshotHistory: {UInt64: EpochSnapshot}

    /// Reserved vault of protocol
    access(self) let reservedProtocolVault: @FlowToken.Vault

    /// Paths
    pub var adminPath: StoragePath

    // Events
    pub event NewQuoteEpoch(epoch: UInt64)
    pub event RegisterNewDelegator(nodeID: String, delegatorID: UInt32)
    pub event ReceiveStakingReward(realReceivedAmount: UFix64, lastEstimatedAmount: UFix64, epoch: UInt64)
    pub event RewardPermanentLoss(loss: UFix64, epoch: UInt64)
    pub event DepositProtocolReservedVault(amount: UFix64, purpose: String)
    pub event RestakeSlashedTokens(amount: UFix64, type: String, epoch: UInt64)
    pub event RedelegateTokens(amount: UFix64, epoch: UInt64)
    pub event CompoundReward(rewardAmount: UFix64, epoch: UInt64)
    pub event CollectDelegators(startIndex: Int, endIndex: Int, pendingDelegatorCount: Int)
    pub event BotTransferCommittedTokens(from: String, to: String, amount: UFix64)
    pub event BotProcessUnstakeRequests(amount: UFix64, nodeIDToUnstake: String, delegatorIDToUnstake: UInt32, leftReservedUnstakeRequest: UFix64)
    pub event BotRemoveDelegator(nodeID: String, delegatorID: UInt32, uuid: UInt64)
    pub event SetApprovedNodeList(nodeIDs: {String: UFix64}, reservedNodeIDToStake: String)
    pub event UpsertApprovedNode(nodeID: String, weight: UFix64)
    pub event SetReservedNode(from: String, to: String)
    pub event SlashApprovedNode(nodeID: String)
    pub event RemoveApprovedNode(nodeID: String)
    pub event Redelegate(nodeID: String, delegatorID: UInt32, unstakeAmount: UFix64)
    
    /// Reserved parameter fields: {ParamName: Value}
    access(self) let _reservedFields: {String: AnyStruct}

    

    /// Epoch snapshot
    ///
    /// The bots will collect all delegators (up to 50,000) when new flow chain epoch start
    /// Calculate the new stFlow price after all rewards collected
    ///
    pub struct EpochSnapshot {

        /// Snapshot for which epoch
        pub let snapshotEpochCounter: UInt64

        /// Price: stFlow to Flow (>= 1.0)
        pub var scaledQuoteStFlowFlow: UInt256
        /// Price: Flow to stFlow (<= 1.0)
        pub var scaledQuoteFlowStFlow: UInt256
        
        /// Total staked amount of all delegators
        pub var allDelegatorStaked: UFix64
        /// Total committed amount of all delegators
        pub var allDelegatorCommitted: UFix64
        /// Total requests to unstake of all delegators
        pub var allDelegatorRequestedToUnstake: UFix64

        /// Total rewards received from all delegators
        pub var receivedReward: UFix64
        /// Estimated rewards which will be received at the next epoch beginning
        pub var futureReward: UFix64

        /// Cached delegator infos
        pub var delegatorInfoDict: {String: {UInt32: FlowIDTableStaking.DelegatorInfo}}
        
        /// Committed tokens will be canceled on slashed nodes
        /// Re-commit these tokens on the current epoch
        pub var slashedCommittedTokens: UFix64
        /// Staked tokens on slashed nodes will be forcely moved to unstaking vault
        /// Re-commit when unstaking complete
        pub var slashedStakedTokens: UFix64

        /// Tokens that requested to unstake for redelegation in thie epoch
        pub var redelegatedTokensToRequestUnstake: UFix64
        /// Tokens in unstaking vault for redelegation
        pub var redelegatedTokensUnderUnstaking: UFix64


        /// Start time of new quote epoch
        pub var quoteEpochStartTimestamp: UFix64
        pub var quoteEpochStartBlockHeight: UInt64
        pub var quoteEpochStartBlockView: UInt64

        /// Insert or Update the collected delegator info
        ///
        access(contract) fun upsertDelegatorInfo(nodeID: String, delegatorID: UInt32) {
            let delegatroInfo = FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)
            
            if self.delegatorInfoDict.containsKey(nodeID) == false {
                self.delegatorInfoDict[nodeID] = {}
            } else {
                if self.delegatorInfoDict[nodeID]!.containsKey(delegatorID) == true {
                    self.allDelegatorStaked = self.allDelegatorStaked - self.delegatorInfoDict[nodeID]![delegatorID]!.tokensStaked
                    self.allDelegatorCommitted = self.allDelegatorCommitted - self.delegatorInfoDict[nodeID]![delegatorID]!.tokensCommitted
                    self.allDelegatorRequestedToUnstake = self.allDelegatorRequestedToUnstake - self.delegatorInfoDict[nodeID]![delegatorID]!.tokensRequestedToUnstake
                }
            }

            self.allDelegatorStaked = self.allDelegatorStaked + delegatroInfo.tokensStaked
            self.allDelegatorCommitted = self.allDelegatorCommitted + delegatroInfo.tokensCommitted
            self.allDelegatorRequestedToUnstake = self.allDelegatorRequestedToUnstake + delegatroInfo.tokensRequestedToUnstake

            self.delegatorInfoDict[nodeID]!.insert(key: delegatorID, delegatroInfo)
        }

        /// Snapshot the epoch info after all delegator's rewards & unstaked tokens have been collected
        /// stFlow prince will be calculated and the new quote epoch will begin
        ///
        access(contract) fun snapshotAfterCollection() {
            pre {
                // If all delegators have been collected
                self.getCollectedDelegatorCount() == DelegatorManager.allDelegators.length: "All delegators should be updated correctly"
                FlowEpoch.currentEpochCounter > DelegatorManager.quoteEpochCounter: "Snapshot should be catched before new quote epoch start"
            }

            // Record current received reward
            if LiquidStakingConfig.rewardFee > 0.0 {
                let feeVault <- DelegatorManager.totalRewardedVault.withdraw(amount: DelegatorManager.totalRewardedVault.balance * LiquidStakingConfig.rewardFee)
                DelegatorManager.depositProtocolReservedVault(flowVault: <-feeVault, purpose: "reward fee")
            }
            self.receivedReward = DelegatorManager.totalRewardedVault.balance

            // Estimate and record future reward
            self.estimateFutureReward()
            
            // Epoch starttime record
            let currentBlock = getCurrentBlock()
            self.quoteEpochStartTimestamp = currentBlock.timestamp
            self.quoteEpochStartBlockHeight = currentBlock.height
            self.quoteEpochStartBlockView = currentBlock.view
            
            // TODO for testing
            log("--> all delegator updated on epoch start, delegator count: ".concat(DelegatorManager.allDelegators.length.toString()))
            log("--> total staked amount: ".concat(self.allDelegatorStaked.toString()))
            log("--> total reward received: ".concat(self.receivedReward.toString()))
            log("--> cal future reward: ".concat(self.futureReward.toString()))
        }

        /// Estimate reward that will be received next epoch
        ///
        access(self) fun estimateFutureReward() {

            let lastEpochCounter = DelegatorManager.quoteEpochCounter
            // Reward estimated on last epoch
            var lastFutureAmount = 0.0
            if DelegatorManager.epochSnapshotHistory.containsKey(lastEpochCounter) {
                lastFutureAmount = DelegatorManager.epochSnapshotHistory[lastEpochCounter]!.futureReward
            }

            // A late payment of rewards by the flow chain or a node being punished may cause this reward loss
            // The loss will be made up in the next epoch's reward calculation to ensure the stability of the overall rewards.
            var rewardLoss = 0.0
            if lastFutureAmount > self.receivedReward {
                rewardLoss = lastFutureAmount - self.receivedReward
                emit RewardPermanentLoss(loss: rewardLoss, epoch: FlowEpoch.currentEpochCounter)
            }

            // Estimate the future reward
            var futureReward = LiquidStakingConfig.calcStakedPayout(stakedAmount: self.allDelegatorStaked)
            self.futureReward = futureReward

            emit ReceiveStakingReward(realReceivedAmount: self.receivedReward, lastEstimatedAmount: lastFutureAmount, epoch: FlowEpoch.currentEpochCounter)
        }
        
        /// Delegator count that has been collected
        pub fun getCollectedDelegatorCount(): Int {
            let nodeIDs = self.delegatorInfoDict.keys
            var totalCount = 0
            for nodeID in nodeIDs {
                totalCount = totalCount + self.delegatorInfoDict[nodeID]!.length
            }
            return totalCount
        }

        ///
        pub fun borrowDelegatorInfo(nodeID: String, delegatorID: UInt32): &FlowIDTableStaking.DelegatorInfo? {
            if self.delegatorInfoDict.containsKey(nodeID) == false {
                return nil
            }
            return &self.delegatorInfoDict[nodeID]![delegatorID] as &FlowIDTableStaking.DelegatorInfo?
        }

        ///
        access(contract) fun addSlashedCommittedTokens(amount: UFix64) {
            self.slashedCommittedTokens = self.slashedCommittedTokens + amount
        }

        ///
        access(contract) fun addSlashedStakedTokens(amount: UFix64) {
            self.slashedStakedTokens = self.slashedStakedTokens + amount
        }

        ///
        access(contract) fun addRedelegatedTokensToRequestUnstake(amount: UFix64) {
            self.redelegatedTokensToRequestUnstake = self.redelegatedTokensToRequestUnstake + amount
        }

        ///
        access(contract) fun setRedelegatedTokensUnderUnstaking(amount: UFix64) {
            self.redelegatedTokensUnderUnstaking = self.redelegatedTokensUnderUnstaking + amount
        }

        ///
        access(contract) fun setStflowPrice(stFlowToFlow: UInt256, flowToStFlow: UInt256) {
            self.scaledQuoteStFlowFlow = stFlowToFlow
            self.scaledQuoteFlowStFlow = flowToStFlow
        }

        init(epochCounter: UInt64) {
            self.snapshotEpochCounter = epochCounter

            self.allDelegatorStaked = 0.0
            self.allDelegatorCommitted = 0.0
            self.allDelegatorRequestedToUnstake = 0.0

            self.receivedReward = 0.0
            self.futureReward = 0.0

            self.scaledQuoteStFlowFlow = LiquidStakingConfig.UFix64ToScaledUInt256(1.0)
            self.scaledQuoteFlowStFlow = LiquidStakingConfig.UFix64ToScaledUInt256(1.0)

            self.delegatorInfoDict = {}

            self.slashedCommittedTokens = 0.0
            self.slashedStakedTokens = 0.0

            self.redelegatedTokensToRequestUnstake = 0.0
            self.redelegatedTokensUnderUnstaking = 0.0

            self.quoteEpochStartTimestamp = 0.0
            self.quoteEpochStartBlockHeight = 0
            self.quoteEpochStartBlockView = 0
        }
    }

    /// Start new quote epoch after all delegators have been collected
    ///
    access(self) fun nextQuoteEpoch() {
        pre {
            FlowEpoch.currentEpochCounter > DelegatorManager.quoteEpochCounter: "Snapshot should be catched before new quote epoch start"
        }

        // Snapshot epoch info
        self.epochSnapshotHistory[FlowEpoch.currentEpochCounter]!.snapshotAfterCollection()

        // Check if approved nodes is stakable
        self.filterApprovedNodeListOnEpochStart()

        // Re-commit slashed tokens
        self.restakeSlashedTokens()

        // Re-commit redelegated tokens
        self.redelegateTokens()

        // Compound rewards that collected this epoch
        self.compoundRewards()

        // Calculate stFlow price for this epoch
        self.stFlowQuote()

        // Finally, start the new quote epoch
        self.quoteEpochCounter = FlowEpoch.currentEpochCounter
        
        emit NewQuoteEpoch(epoch: self.quoteEpochCounter)
    }

    /// Calculate the stFlow price
    ///
    ///                      [currentReward] + [totalCommitted] + [totalStaked]
    /// stFlow_Flow price = ---------------------------------------------------
    ///                                    [stFlow totalSupply]
    ///
    access(self) fun stFlowQuote() {
        pre {
            FlowEpoch.currentEpochCounter > self.quoteEpochCounter: "stFlow quote can only be called before new quote epoch start"
        }

        let newEpochSnapshot: &EpochSnapshot = &(self.epochSnapshotHistory[FlowEpoch.currentEpochCounter]!) as &EpochSnapshot
        
        let currentReward = DelegatorManager.totalRewardedVault.balance

        let totalCommitted = newEpochSnapshot.allDelegatorCommitted

        let totalStaked = newEpochSnapshot.allDelegatorStaked
                                    - DelegatorManager.reservedRequestedToUnstakeAmount
                                    - newEpochSnapshot.allDelegatorRequestedToUnstake
                                    + newEpochSnapshot.slashedStakedTokens
                                    + newEpochSnapshot.redelegatedTokensToRequestUnstake
                                    + newEpochSnapshot.redelegatedTokensUnderUnstaking
        
        let flowSupply = currentReward + totalCommitted + totalStaked
        let stFlowSupply = stFlowToken.totalSupply

        var stFlow_Flow: UInt256 = 0
        var Flow_stFlow: UInt256 = 0
        if flowSupply == 0.0 || stFlowSupply == 0.0 {
            stFlow_Flow = LiquidStakingConfig.UFix64ToScaledUInt256(1.0)
            Flow_stFlow = LiquidStakingConfig.UFix64ToScaledUInt256(1.0)
        } else {
            let scaledFlowSupply = LiquidStakingConfig.UFix64ToScaledUInt256(flowSupply)
            let scaledStFlowSupply = LiquidStakingConfig.UFix64ToScaledUInt256(stFlowSupply)

            stFlow_Flow = scaledFlowSupply * LiquidStakingConfig.scaleFactor / scaledStFlowSupply
            Flow_stFlow = scaledStFlowSupply * LiquidStakingConfig.scaleFactor / scaledFlowSupply
        }
        
        newEpochSnapshot.setStflowPrice(stFlowToFlow: stFlow_Flow, flowToStFlow: Flow_stFlow)
    }
    
    /// Deposit flowToken to the reserved delegator
    ///
    /// Called by stake()
    ///
    access(account) fun depositToCommitted(flowVault: @FlowToken.Vault) {
        // To default stake node
        var reservedDelegator = self.createorborrowApprovedDelegator(nodeID: self.reservedNodeIDToStake)

        // Stake to committed 
        reservedDelegator.delegateNewTokens(from: <-flowVault)

        // Update snapshot
        self.borrowCurrentEpochSnapshot().upsertDelegatorInfo(nodeID: reservedDelegator.nodeID, delegatorID: reservedDelegator.id)
    }

    /// Withdraw flow tokens from committed vault
    ///
    /// Called by unstakeQuickly()
    ///
    access(account) fun withdrawFromCommitted(amount: UFix64): @FlowToken.Vault {
        // All committed tokens will be accumulated in the default node's delegator
        // until they are distributed to other delegators by bots before the end of the staking stage
        let reservedDelegator = self.borrowApprovedDelegator(nodeID: self.reservedNodeIDToStake)!
        let reservedDelegatroInfo = FlowIDTableStaking.DelegatorInfo(nodeID: reservedDelegator.nodeID, delegatorID: reservedDelegator.id)
        
        assert(reservedDelegatroInfo.tokensCommitted >= amount, message: "Not enough committed tokens to withdraw")

        // Cancel the committed tokens from delegator
        reservedDelegator.requestUnstaking(amount: amount)

        let flowVault <- reservedDelegator.withdrawUnstakedTokens(amount: amount)

        // Update snapshot
        self.borrowCurrentEpochSnapshot().upsertDelegatorInfo(nodeID: reservedDelegator.nodeID, delegatorID: reservedDelegator.id)

        return <-(flowVault as! @FlowToken.Vault)
    }

    /// All unstaking requests will be reserved before staking end
    ///
    /// Called by unstakeSlowly()
    ///
    access(account) fun requestWithdrawFromStaked(amount: UFix64) {

        let currentEpochSnapshot = self.borrowCurrentEpochSnapshot()
        assert(
            currentEpochSnapshot.allDelegatorStaked + currentEpochSnapshot.allDelegatorCommitted
                >=
                amount + currentEpochSnapshot.allDelegatorRequestedToUnstake + self.reservedRequestedToUnstakeAmount
            , message: LiquidStakingError.ErrorEncode(
                msg: "Not enough tokens to request unstake",
                err: LiquidStakingError.ErrorCode.INVALID_PARAMETERS
            )
        )
    
        let leftStakedTokens = currentEpochSnapshot.allDelegatorStaked
                                + currentEpochSnapshot.allDelegatorCommitted
                                - currentEpochSnapshot.allDelegatorRequestedToUnstake
                                - self.reservedRequestedToUnstakeAmount
        
        // reserve unstake requests
        self.reservedRequestedToUnstakeAmount = self.reservedRequestedToUnstakeAmount + amount
    }

    /// Withdraw tokens from unstaked vault
    ///
    /// Called by cashingUnstakingVoucher()
    ///
    access(account) fun withdrawFromUnstaked(amount: UFix64): @FlowToken.Vault {
        return <-(self.totalUnstakedVault.withdraw(amount: amount) as! @FlowToken.Vault)
    }
    
    /// Migrate Delegator
    ///
    /// Called by migrate()
    ///
    access(account) fun migrateDelegator(delegator: @FlowIDTableStaking.NodeDelegator) {
        let nodeID = delegator.nodeID
        let delegatorID = delegator.id
        let uuid = delegator.uuid
        
        self.insertMigratedDelegatorUUID(nodeID: nodeID, delegatorID: delegatorID, uuid: uuid)

        // Update snapshot
        self.borrowCurrentEpochSnapshot().upsertDelegatorInfo(nodeID: delegator.nodeID, delegatorID: delegator.id)
        
        self.allDelegators[uuid] <-! delegator
    }

    /// Compound reward
    ///
    access(self) fun compoundRewards() {
        let rewardVault <- self.totalRewardedVault.withdraw(amount: self.totalRewardedVault.balance)
        emit CompoundReward(rewardAmount: rewardVault.balance, epoch: FlowEpoch.currentEpochCounter)
        self.depositToCommitted(flowVault: <-(rewardVault as! @FlowToken.Vault))
    }

    ///
    access(self) fun restakeSlashedTokens() {
        pre {
            FlowEpoch.currentEpochCounter > self.quoteEpochCounter: "recommit slashed tokens can only be called before new quote epoch start"
        }

        let newEpochSnapshot: &EpochSnapshot = &(self.epochSnapshotHistory[FlowEpoch.currentEpochCounter]!) as &EpochSnapshot
        let lastEpochSnapshot: &EpochSnapshot = &(self.epochSnapshotHistory[self.quoteEpochCounter]!) as &EpochSnapshot

        // restake committed tokens
        if newEpochSnapshot.slashedCommittedTokens > 0.0 {
            let slashedCommittedTokens <- self.totalUnstakedVault.withdraw(amount: newEpochSnapshot.slashedCommittedTokens)
            self.depositToCommitted(flowVault: <-(slashedCommittedTokens as! @FlowToken.Vault))
            
            emit RestakeSlashedTokens(amount: newEpochSnapshot.slashedCommittedTokens, type: "committed", epoch: FlowEpoch.currentEpochCounter)
        }

        // restake staked tokens
        if lastEpochSnapshot.slashedStakedTokens > 0.0 {
            let slashedStakedTokens <- self.totalUnstakedVault.withdraw(amount: lastEpochSnapshot.slashedStakedTokens)
            self.depositToCommitted(flowVault: <-(slashedStakedTokens as! @FlowToken.Vault))
            
            emit RestakeSlashedTokens(amount: lastEpochSnapshot.slashedStakedTokens, type: "staked", epoch: FlowEpoch.currentEpochCounter)
        }
    }

    ///
    access(self) fun redelegateTokens() {
        pre {
            FlowEpoch.currentEpochCounter > self.quoteEpochCounter: "redelegate tokens can only be called before new quote epoch start"
        }

        let newEpochSnapshot: &EpochSnapshot = &(self.epochSnapshotHistory[FlowEpoch.currentEpochCounter]!) as &EpochSnapshot
        let lastEpochSnapshot: &EpochSnapshot = &(self.epochSnapshotHistory[self.quoteEpochCounter]!) as &EpochSnapshot

        // request unstake tokens -> unstaking tokens
        if lastEpochSnapshot.redelegatedTokensToRequestUnstake > 0.0 {
            newEpochSnapshot.setRedelegatedTokensUnderUnstaking(amount: lastEpochSnapshot.redelegatedTokensToRequestUnstake)
        }

        // unstaking tokens -> unstaked -> recommit
        if lastEpochSnapshot.redelegatedTokensUnderUnstaking > 0.0 {
            let redelegatedVault <- self.totalUnstakedVault.withdraw(amount: lastEpochSnapshot.redelegatedTokensUnderUnstaking)
            self.depositToCommitted(flowVault: <-(redelegatedVault as! @FlowToken.Vault))

            emit RedelegateTokens(amount: lastEpochSnapshot.redelegatedTokensUnderUnstaking, epoch: FlowEpoch.currentEpochCounter)
        }
    }

    /// Collect all delegators on new epoch start
    ///
    /// Move unstaked & rewarded vaults from delegators -> totalUnstaked & totalRewarded vaults
    /// Collection will start immediately after the new epoch starts
    /// Due to the large delegator counts, collection will be processed in batches
    ///
    /// During this short window, no new stake requests will be accepted until all reward tokens are correctly collected,
    /// which will recalculate the price of stFlow this epoch
    ///
    /// Anyone can call to keep protocol moving
    ///
    pub fun collectDelegatorsOnEpochStart(startIndex: Int, endIndex: Int) {
        pre {
            FlowEpoch.currentEpochCounter > self.quoteEpochCounter: "No need to collect, only at the beginning of each epoch"
        }

        // When auto reward pay open
        if FlowEpoch.automaticRewardsEnabled() == true {
            if self.quoteEpochCounter > 0 {
                assert(
                    FlowEpoch.getEpochMetadata(self.quoteEpochCounter)!.rewardsPaid == true, message:
                        LiquidStakingError.ErrorEncode(
                            msg: "Flow has not paid the reward yet at epoch ".concat(self.quoteEpochCounter.toString()),
                            err: LiquidStakingError.ErrorCode.STAKING_REWARD_NOT_PAID
                        )
                )
            }
        }
        
        if self.epochSnapshotHistory.containsKey(FlowEpoch.currentEpochCounter) == false {
            self.epochSnapshotHistory[FlowEpoch.currentEpochCounter] = EpochSnapshot(epochCounter: FlowEpoch.currentEpochCounter)
        }
        
        let newEpochSnapshot: &EpochSnapshot = &(self.epochSnapshotHistory[FlowEpoch.currentEpochCounter]!) as &EpochSnapshot
        let lastEpochSnapshot: &EpochSnapshot = &(self.epochSnapshotHistory[self.quoteEpochCounter]!) as &EpochSnapshot

        let delegatorUUIDList = self.allDelegators.keys
        let delegatorLength = delegatorUUIDList.length
        var index = startIndex
        while index <= endIndex && index < delegatorLength {
            let uuid = delegatorUUIDList[index]
            let delegator = self.borrowDelegator(uuid: uuid)!
            let nodeID = delegator.nodeID
            let delegatorID = delegator.id

            let currentDelegatorInfo = FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)
            let lastDelegatorInfo = lastEpochSnapshot.borrowDelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)
            assert(currentDelegatorInfo.tokensCommitted == 0.0, message: "Committed tokens has not been moved to staked vault")

            if (lastDelegatorInfo != nil) {
                if FlowEpoch.automaticRewardsEnabled() == false {
                    // Hmm... the reward is delay paid again
                    if lastDelegatorInfo!.tokensStaked > LiquidStakingConfig.minStakingAmount && currentDelegatorInfo.tokensRewarded == 0.0 {
                        // Clear the previous collection, waiting for reward payment.
                        self.epochSnapshotHistory.remove(key: FlowEpoch.currentEpochCounter)
                        return
                    }
                }

                // !!
                // The node was removed by the FlowIDTableStaking.removeUnapprovedNodes()
                // All the staked tokens will be moved to -> unstaking vault
                //         committed tokens -> unstaked vault
                if currentDelegatorInfo.tokensStaked == 0.0
                    &&
                    (lastDelegatorInfo!.tokensCommitted > 0.0 || (lastDelegatorInfo!.tokensStaked - lastDelegatorInfo!.tokensRequestedToUnstake > 0.0)) {
                    
                    // Tokens that are forcibly removed, need to be re-committed
                    let tokensToRecommitNow = lastDelegatorInfo!.tokensCommitted
                    let tokensToRecommitNextEpoch = lastDelegatorInfo!.tokensStaked - lastDelegatorInfo!.tokensRequestedToUnstake
                    
                    newEpochSnapshot.addSlashedCommittedTokens(amount: tokensToRecommitNow)
                    newEpochSnapshot.addSlashedStakedTokens(amount: tokensToRecommitNextEpoch)
                }
            }

            // Collect rewards tokens
            if currentDelegatorInfo.tokensRewarded > 0.0 {
                self.totalRewardedVault.deposit(from: <-delegator.withdrawRewardedTokens(amount: currentDelegatorInfo.tokensRewarded))
            }
            
            // Collect unstaked tokens
            if currentDelegatorInfo.tokensUnstaked > 0.0 {
                self.totalUnstakedVault.deposit(from: <-delegator.withdrawUnstakedTokens(amount: currentDelegatorInfo.tokensUnstaked))
            }

            // Update snapshot
            newEpochSnapshot.upsertDelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)

            index = index + 1
        }
        
        // If all delegators have been collected
        let collectedCount = newEpochSnapshot.getCollectedDelegatorCount()
        if collectedCount == self.allDelegators.length {
            self.nextQuoteEpoch()
        }

        emit CollectDelegators(startIndex: startIndex, endIndex: endIndex, pendingDelegatorCount: self.allDelegators.length - collectedCount)
    }
    
    
    ///
    access(contract) fun insertMigratedDelegatorUUID(nodeID: String, delegatorID: UInt32, uuid: UInt64) {
        if self.migratedDelegatorIDs.containsKey(nodeID) == false {
            self.migratedDelegatorIDs[nodeID] = {}
        }
        
        assert(self.migratedDelegatorIDs[nodeID]!.containsKey(delegatorID) == false, message: "Reinsert delegator uuid")
        
        self.migratedDelegatorIDs[nodeID]!.insert(key: delegatorID, uuid)
    }

    /// Check protocol's approved nodes with FlowIDTableStaking.getStakedNodeIDs()
    ///
    access(self) fun filterApprovedNodeListOnEpochStart() {
        let stakableNodeList = FlowIDTableStaking.getStakedNodeIDs()
        let currentApprovedNodeIDList = self.approvedNodeIDList.keys

        for nodeID in currentApprovedNodeIDList {
            if stakableNodeList.contains(nodeID) {
                continue
            }

            //
            self.removeApprovedNodeID(nodeID: nodeID)

            emit SlashApprovedNode(nodeID: nodeID)

            if nodeID == self.reservedNodeIDToStake {
                self.reservedNodeIDToStake = ""
            }
        }

        if self.reservedNodeIDToStake == "" && self.approvedNodeIDList.length > 0 {
            self.reservedNodeIDToStake = self.approvedNodeIDList.keys[0]
        }
    }
    
    ///
    access(self) fun borrowDelegator(uuid: UInt64): &FlowIDTableStaking.NodeDelegator? {
        if self.allDelegators[uuid] != nil {
            let delegatorRef = (&self.allDelegators[uuid] as &FlowIDTableStaking.NodeDelegator?)!
            return delegatorRef
        } else {
            return nil
        }
    }

    ///
    access(self) fun removeDelegator(uuid: UInt64) {
        let tmpDelegator <- self.allDelegators[uuid] <- nil
        destroy tmpDelegator
    }

    ///
    access(self) fun borrowApprovedDelegator(nodeID: String): &FlowIDTableStaking.NodeDelegator? {
        pre {
            self.approvedDelegatorIDs.containsKey(nodeID): "Borrow a node not in the approved list"
        }
        let uuid = self.approvedDelegatorIDs[nodeID]!
        return self.borrowDelegator(uuid: uuid)
    }

    /// Register delegator on new staking node
    ///
    access(self) fun registerNewDelegator(_ nodeID: String) {
        pre {
            self.isNodeDelegated(nodeID) == false: "Cannot register a delegator for a node that is already being delegated to"
            self.approvedNodeIDList.containsKey(nodeID): "Cannot register a delegator that out of approved list"
            FlowIDTableStaking.getStakedNodeIDs().contains(nodeID): "Cannot stake to an invalid staked node: ".concat(nodeID)
        }

        let nodeDelegator <- FlowIDTableStaking.registerNewDelegator(nodeID: nodeID)
        emit RegisterNewDelegator(nodeID: nodeDelegator.nodeID, delegatorID: nodeDelegator.id)

        let uuid = nodeDelegator.uuid
        self.approvedDelegatorIDs[nodeDelegator.nodeID] = uuid
        self.allDelegators[uuid] <-! nodeDelegator
    }

    ///
    access(self) fun createorborrowApprovedDelegator(nodeID: String): &FlowIDTableStaking.NodeDelegator {
        if self.isNodeDelegated(nodeID) == false {
            self.registerNewDelegator(nodeID)
        }
        return self.borrowApprovedDelegator(nodeID: nodeID)!
    }

    /// Remove approved node
    ///
    access(self) fun removeApprovedNodeID(nodeID: String) {
        pre {
            DelegatorManager.approvedNodeIDList.containsKey(nodeID): "Nonexistent node ID to remove"
        }
        // No delegator on this nodeID
        if DelegatorManager.approvedDelegatorIDs.containsKey(nodeID) == false {
            DelegatorManager.approvedNodeIDList.remove(key: nodeID)    
            return
        }

        let uuid = DelegatorManager.approvedDelegatorIDs[nodeID]!
        let delegatorRef = DelegatorManager.borrowDelegator(uuid: uuid)!
        let delegatorInfo = FlowIDTableStaking.DelegatorInfo(nodeID: delegatorRef.nodeID, delegatorID: delegatorRef.id)
        // Committed tokens should be moved out before removing, especially if removing the default stake node
        assert(delegatorInfo.tokensCommitted == 0.0, message: "Committed tokens should be moved out before removing")
        
        DelegatorManager.approvedNodeIDList.remove(key: nodeID)
        
        // Move delegator record from approved list to migrated list
        DelegatorManager.approvedDelegatorIDs.remove(key: nodeID)
        DelegatorManager.insertMigratedDelegatorUUID(nodeID: delegatorRef.nodeID, delegatorID: delegatorRef.id, uuid: uuid)
    }



    ///
    pub fun depositProtocolReservedVault(flowVault: @FungibleToken.Vault, purpose: String) {
        emit DepositProtocolReservedVault(amount: flowVault.balance, purpose: purpose)
        self.reservedProtocolVault.deposit(from: <-flowVault)
    }

    /// Valid staking = flowTokens backed by stFlowTokens
    ///
    pub fun getTotalValidStakingAmount(): UFix64 {
        let currentEpochSnapshot = self.borrowQuoteEpochSnapshot()
        let totalValidStakingAmount = currentEpochSnapshot.allDelegatorStaked 
                                        + currentEpochSnapshot.allDelegatorCommitted 
                                        + self.totalRewardedVault.balance
                                        - self.reservedRequestedToUnstakeAmount
                                        - currentEpochSnapshot.allDelegatorRequestedToUnstake
        return totalValidStakingAmount
    }

    ///
    pub fun borrowEpochSnapshot(at: UInt64): &EpochSnapshot {
        return &self.epochSnapshotHistory[at]! as &EpochSnapshot
    }

    ///
    pub fun borrowCurrentEpochSnapshot(): &EpochSnapshot {
        return self.borrowEpochSnapshot(at: FlowEpoch.currentEpochCounter)
    }

    ///
    pub fun borrowQuoteEpochSnapshot():  &EpochSnapshot {
        return self.borrowEpochSnapshot(at: self.quoteEpochCounter)
    }

    ///
    pub fun getDelegatorUUIDByID(nodeID: String, delegatorID: UInt32): UInt64? {
        if self.migratedDelegatorIDs.containsKey(nodeID) {
            if self.migratedDelegatorIDs[nodeID]!.containsKey(delegatorID) {
                return self.migratedDelegatorIDs[nodeID]![delegatorID]
            }
        }
        if let delegator = self.borrowApprovedDelegator(nodeID: nodeID) {
            if delegator.id == delegatorID {
                return self.approvedDelegatorIDs[nodeID]!
            }
        }
        
        return nil
    }

    /// 
    pub fun isNodeDelegated(_ nodeID: String): Bool {
        return self.approvedDelegatorIDs.containsKey(nodeID)
    }

    /// Staking Node ID Whitelist
    ///
    pub fun getApprovedNodeList(): {String: UFix64} {
        return self.approvedNodeIDList
    }

    /// Get all approved delegators
    /// Up to 400 nodes, do not worry about the gas-limit
    ///
    pub fun getApprovedDelegatorIDs(): {String: UInt64} {
        return self.approvedDelegatorIDs
    }

    /// Node ID list that migrated involved
    /// Up to 400 nodes, do not worry about the gas-limit
    ///
    pub fun getMigratedNodeIDList(): [String] {
        return self.migratedDelegatorIDs.keys
    }

    /// Migrate delegator length that staked on one node
    ///
    pub fun getMigratedDelegatorLength(nodeID: String): Int {
        return self.migratedDelegatorIDs[nodeID]!.keys.length
    }
    
    /// Sliced get migrated delegators ID list by nodeID
    ///
    pub fun getSlicedMigratedDelegatorIDList(nodeID: String, from: Int, to: Int): [UInt32] {
        var upTo = to
        if upTo > self.migratedDelegatorIDs[nodeID]!.length {
            upTo = self.migratedDelegatorIDs[nodeID]!.length
        }
        return self.migratedDelegatorIDs[nodeID]!.keys.slice(from: from, upTo: upTo)
    }

    /// 
    pub fun getProtocolReservedVaultBalance(): UFix64 {
        return self.reservedProtocolVault.balance
    }

    ///
    pub fun getDelegatorInfoByUUID(delegatorUUID: UInt64): FlowIDTableStaking.DelegatorInfo {
        let delegator = self.borrowDelegator(uuid: delegatorUUID)!
        let nodeID = delegator.nodeID
        let delegatorID = delegator.id
        return FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)
    }

    ///
    pub fun getApprovedDelegatorInfoByNodeID(nodeID: String): FlowIDTableStaking.DelegatorInfo {
        let delegator = self.borrowDelegator(uuid: self.approvedDelegatorIDs[nodeID]!)!
        let nodeID = delegator.nodeID
        let delegatorID = delegator.id
        return FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)
    }

    ///
    pub fun getSlicedDelegatorUUIDList(from: Int, to: Int): [UInt64] {
        let UUIDs = self.allDelegators.keys
        var upTo = to
        if upTo > UUIDs.length {
            upTo = UUIDs.length
        }
        return UUIDs.slice(from: from, upTo: upTo)
    }

    ///
    pub fun getTotalUnstakedVaultBalance(): UFix64 {
        return self.totalUnstakedVault.balance
    }

    ///
    pub fun getDelegatorsLength(): Int {
        return self.allDelegators.keys.length
    }

    /// Bot
    ///
    pub resource Bot {

        /// Transfer committed tokens among delegators
        pub fun transferCommittedTokens(fromNodeID: String, toNodeID: String, transferAmount: UFix64) {
            var fromDelegator = DelegatorManager.borrowApprovedDelegator(nodeID: fromNodeID)!
            var toDelegator = DelegatorManager.borrowApprovedDelegator(nodeID: toNodeID)!
            let fromDelegatroInfo = FlowIDTableStaking.DelegatorInfo(nodeID: fromNodeID, delegatorID: fromDelegator.id)
            
            assert(fromDelegatroInfo.tokensCommitted >= transferAmount, message: "Transfer committed token is out of limit")
            
            // withdraw committed
            fromDelegator.requestUnstaking(amount: transferAmount)
            let transferVault <- fromDelegator.withdrawUnstakedTokens(amount: transferAmount)

            // deposit committed
            toDelegator.delegateNewTokens(from: <- transferVault)

            // update snapshot
            DelegatorManager.borrowCurrentEpochSnapshot().upsertDelegatorInfo(nodeID: fromDelegator.nodeID, delegatorID: fromDelegator.id)
            DelegatorManager.borrowCurrentEpochSnapshot().upsertDelegatorInfo(nodeID: toDelegator.nodeID, delegatorID: toDelegator.id)

            emit BotTransferCommittedTokens(from: fromNodeID, to: toNodeID, amount: transferAmount)
        }

        /// Reserved unstaking requests --> delegators
        pub fun processUnstakeRequests(requestUnstakeAmount: UFix64, delegatorUUID: UInt64) {
            pre {
                DelegatorManager.reservedRequestedToUnstakeAmount > 0.0: "No unstaked request to handle"
            }
            let delegator = DelegatorManager.borrowDelegator(uuid: delegatorUUID)!
            let delegatorInfo = FlowIDTableStaking.DelegatorInfo(nodeID: delegator.nodeID, delegatorID: delegator.id)
            let tokensStakedLeft = delegatorInfo.tokensStaked - delegatorInfo.tokensRequestedToUnstake
            let tokensCommitted = delegatorInfo.tokensCommitted

            var unstakeAmount = requestUnstakeAmount
            // Try unstaking all
            if unstakeAmount == UFix64.max {
                if DelegatorManager.reservedRequestedToUnstakeAmount >= tokensStakedLeft + tokensCommitted {
                    unstakeAmount = tokensStakedLeft + tokensCommitted
                } else {
                    unstakeAmount = DelegatorManager.reservedRequestedToUnstakeAmount
                }
            }

            assert(DelegatorManager.reservedRequestedToUnstakeAmount >= unstakeAmount, message: "Handle unstake requests out of limit")

            // Request unstaking
            if unstakeAmount <= tokensStakedLeft {
                // unstake only from staked tokens and leave committed tokens 
                delegator.requestUnstaking(amount: unstakeAmount + tokensCommitted)
                let committedVault <- delegator.withdrawUnstakedTokens(amount: tokensCommitted)
                delegator.delegateNewTokens(from: <- committedVault)
            } else {
                // unstake from all staked tokens and some committed tokens
                delegator.requestUnstaking(amount: tokensStakedLeft + tokensCommitted)
                let committedVault <- delegator.withdrawUnstakedTokens(amount: tokensStakedLeft + tokensCommitted - unstakeAmount)
                delegator.delegateNewTokens(from: <- committedVault)
            }
            
            // update reserved unstaked requests
            DelegatorManager.reservedRequestedToUnstakeAmount = DelegatorManager.reservedRequestedToUnstakeAmount - unstakeAmount

            // update snapshot
            DelegatorManager.borrowCurrentEpochSnapshot().upsertDelegatorInfo(nodeID: delegator.nodeID, delegatorID: delegator.id)

            emit BotProcessUnstakeRequests(amount: requestUnstakeAmount, nodeIDToUnstake: delegator.nodeID, delegatorIDToUnstake: delegator.id, leftReservedUnstakeRequest: DelegatorManager.reservedRequestedToUnstakeAmount)
        }

        /// Clean empty migrated delegator and outdated approved delegator
        pub fun cleanDelegators(delegatorUUID: UInt64) {
            let delegator = DelegatorManager.borrowDelegator(uuid: delegatorUUID)!
            let nodeID = delegator.nodeID
            let delegatorID = delegator.id
            let delegatorInfo = FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID)

            assert(
                delegatorInfo.tokensCommitted +
                delegatorInfo.tokensStaked +
                delegatorInfo.tokensUnstaking +
                delegatorInfo.tokensRewarded +
                delegatorInfo.tokensUnstaked +
                delegatorInfo.tokensRequestedToUnstake
                ==
                0.0, message: "Please clean up before deleting"
            )

            // remove migrated delegator
            if DelegatorManager.migratedDelegatorIDs.containsKey(nodeID) {
                if DelegatorManager.migratedDelegatorIDs[nodeID]!.containsKey(delegatorID) {
                    DelegatorManager.migratedDelegatorIDs[nodeID]!.remove(key: delegatorID)
                    DelegatorManager.removeDelegator(uuid: delegatorUUID)
                }
            }
            // remove old approved delegator
            if DelegatorManager.approvedDelegatorIDs.containsKey(nodeID) {
                if DelegatorManager.approvedDelegatorIDs[nodeID]! == delegatorUUID {
                    if DelegatorManager.approvedNodeIDList.containsKey(nodeID) == false {
                        DelegatorManager.approvedDelegatorIDs.remove(key: nodeID)
                        DelegatorManager.removeDelegator(uuid: delegatorUUID)
                    }
                }
            }

            emit BotRemoveDelegator(nodeID: nodeID, delegatorID: delegatorID, uuid: delegatorUUID)
        }
    }

    /// Admin
    ///
    pub resource Admin {

        /// Set approved staking node id list
        ///
        pub fun setApprovedNodeIDList(nodeIDs: {String: UFix64}, reservedNodeIDToStake: String) {
            pre {
                nodeIDs.containsKey(reservedNodeIDToStake): "Reserved node id must be in the list"
                DelegatorManager.approvedNodeIDList.length == 0: "Can only be initialized once"
            }
            DelegatorManager.approvedNodeIDList = nodeIDs
            DelegatorManager.reservedNodeIDToStake = reservedNodeIDToStake

            emit SetApprovedNodeList(nodeIDs : nodeIDs, reservedNodeIDToStake: reservedNodeIDToStake)
        }

        /// Update approved node list
        ///
        pub fun upsertApprovedNodeID(nodeID: String, weight: UFix64) {
            DelegatorManager.approvedNodeIDList[nodeID] = weight

            emit UpsertApprovedNode(nodeID: nodeID, weight: weight)
        }

        /// Remove approved node id
        ///
        pub fun removeApprovedNodeID(nodeID: String) {
            DelegatorManager.removeApprovedNodeID(nodeID: nodeID)

            emit RemoveApprovedNode(nodeID: nodeID)
        }

        
        /// Select reserved node among approved node list to be the default staking node
        /// The bots will transfer these reserved tokens to other valid staking nodes
        ///
        pub fun setReservedNodeIDToStake(nodeID: String) {
            pre {
                DelegatorManager.approvedNodeIDList.containsKey(nodeID): "Reserved node id must be in the list"
            }

            emit SetReservedNode(from: DelegatorManager.reservedNodeIDToStake, to: nodeID)

            DelegatorManager.reservedNodeIDToStake = nodeID
        }
        
        /// Create bot
        ///
        pub fun createBot(): @Bot {
            return <- create Bot()
        }

        /// Redelegate
        ///
        pub fun redelegate(nodeID: String, delegatorID: UInt32, unstakeAmount: UFix64) {
            let uuid = DelegatorManager.getDelegatorUUIDByID(nodeID: nodeID, delegatorID: delegatorID)!
            let delegator = DelegatorManager.borrowDelegator(uuid: uuid)!
            let delegatorInfo = DelegatorManager.getDelegatorInfoByUUID(delegatorUUID: uuid)

            // redelegate all committed tokens directly
            if delegatorInfo.tokensCommitted > 0.0 {
                delegator.requestUnstaking(amount: delegatorInfo.tokensCommitted)
                let committedVault <- delegator.withdrawUnstakedTokens(amount: delegatorInfo.tokensCommitted)
                DelegatorManager.depositToCommitted(flowVault: <-(committedVault as! @FlowToken.Vault))
            }

            // request unstake
            delegator.requestUnstaking(amount: unstakeAmount)
            
            // 
            DelegatorManager.borrowCurrentEpochSnapshot().upsertDelegatorInfo(nodeID: delegator.nodeID, delegatorID: delegator.id)
            
            emit Redelegate(nodeID: nodeID, delegatorID: delegatorID, unstakeAmount: unstakeAmount)
        }

        /// Reserved vault control
        ///
        pub fun borrowReservedProtocolVault(): &FungibleToken.Vault {
            return &DelegatorManager.reservedProtocolVault as &FungibleToken.Vault
        }

        /// Replenish rewards
        ///
        pub fun addReward(rewardedVault: @FlowToken.Vault) {
            DelegatorManager.totalRewardedVault.deposit(from: <-rewardedVault)
        }

        /// Register new delegator mannually
        ///
        pub fun registerNewDelegator(nodeID: String) {
            DelegatorManager.registerNewDelegator(nodeID)
        }

    }


    init() {
        self.adminPath = /storage/stakingNodeManagerAdmin

        self.approvedNodeIDList = {}
        self.reservedNodeIDToStake = ""

        self.allDelegators <- {}
        self.approvedDelegatorIDs = {}
        self.migratedDelegatorIDs = {}
        
        
        self.reservedRequestedToUnstakeAmount = 0.0
        self.reservedProtocolVault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
        self.totalUnstakedVault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
        self.totalRewardedVault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
        
        self.quoteEpochCounter = 0
        self.epochSnapshotHistory = {}
        self.epochSnapshotHistory[0] = EpochSnapshot(epochCounter: 0)

        
        self._reservedFields = {}

        self.account.save(<-create Admin(), to: self.adminPath)
    }
}
 