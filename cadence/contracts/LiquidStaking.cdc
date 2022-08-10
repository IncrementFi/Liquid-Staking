import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"

import FlowIDTableStaking from "./flow/FlowIDTableStaking.cdc"
import FlowEpoch from "./flow/FlowEpoch.cdc"

import LiquidStakingInterfaces from "./LiquidStakingInterfaces.cdc"
import LiquidStakingConfig from "./LiquidStakingConfig.cdc"
import stFlowToken from "./stFlowToken.cdc"

pub contract LiquidStaking {
	
	pub var currentEpoch: UInt64

	pub var currentRewardIndex: UFix64

	pub var totalCommitted: UFix64
	pub var totalStaked: UFix64
	pub var totalUnstaking: UFix64
	pub var totalRewarded: UFix64
	pub var totalUnstaked: UFix64
	pub var totalRequestedToUnstake: UFix64

	//
	access(self) let nodeDelegators: @{String: FlowIDTableStaking.NodeDelegator}
	pub var nodeDelegatorInfos: {String: FlowIDTableStaking.DelegatorInfo}
	//
	access(self) var stFlowMinter: @stFlowToken.Minter

	// EpochCounter: rewardIndex
	pub let historyRewardIndex: {UInt64: UFix64}
	//
	//access(self) var userInfos: {Address: UserInfo}

	pub struct UserInfo {
		pub var tokenCommitted: UFix64
		
		
		init() {
			self.tokenCommitted = 0.0
		}
	}

	// Events
	pub event RegisterNewDelegator(nodeID: String, delegatorID: UInt32)

	// Register delegator on new staking node
	access(account) fun registerDelegator(_ nodeID: String) {
		pre {
			self.isNodeDelegated(nodeID) == false: "Cannot register a delegator for a node that is already being delegated to"
		}

		let nodeDelegator <- FlowIDTableStaking.registerNewDelegator(nodeID: nodeID)

		emit RegisterNewDelegator(nodeID: nodeDelegator.nodeID, delegatorID: nodeDelegator.id)

		self.nodeDelegators[nodeDelegator.nodeID] <-! nodeDelegator
	}

	// 用户stake进来的时候，会mint出同等量的stFlow
	// 记录下这个stFlow的 rewardIndex
	// ?? 新生成的stflow vault会跟用户本地的merge?
	// ？？ 有多少是还未被质押的？
	pub fun stake(nodeID: String, stakeVault: @FlowToken.Vault): @stFlowToken.Vault {
		pre {
			stakeVault.balance > 0.0: "Stake amount must be greater than 0"
		}
		
		// new stake node
		if self.isNodeDelegated(nodeID) == false {
			self.registerDelegator(nodeID)
		}

		let stakeAmount = stakeVault.balance
		let nodeDelegator = self.borrowDelegator(nodeID)!

		// update total record
		self.totalCommitted = self.totalCommitted + stakeAmount

		// On stake auction stage, committed tokens will be staked in the next epoch.
		if (FlowIDTableStaking.stakingEnabled()) {
			// Delegate into committed vault of FlowIDTableStaking
			nodeDelegator.delegateNewTokens(from: <-stakeVault)
			// Mint stFlow
			let stFlowVault <- self.stFlowMinter.mintTokens(amount: stakeAmount)

			return <-stFlowVault
		}
		// When auction stage ends and the next epoch does not start, tokens will be held and committed until the new epoch start.
		else {
			// TODO
			destroy stakeVault
			assert(false, message: "not in auction stage")

			return <-self.stFlowMinter.mintTokens(amount: 0.0)
		}
	}

	// 有多少是立马可以unstake的？
	// 有多少是锁住的需要被记录下周提取的？
	pub fun unstake(nodeID: String, stFlowVault: @stFlowToken.Vault) {
		// 判断此nodeID中是否有足够的量可以unstake

		// 上传的stFlowVault中有多少是committed的？
		//stFlowVault.

		destroy stFlowVault
	}
	
	// ?? 单独claim奖励？ 直接claim成Flow
	pub fun claim() {

	}

	pub fun updateOnNewEpoch() {
		// 进入新epoch时，将上个epoch产生的reward全部收集起来
		if FlowEpoch.currentEpochCounter > self.currentEpoch {
			
			let newDelegatorInfos: {String: FlowIDTableStaking.DelegatorInfo} = {}
			// 

			//self.nodeDelegatorInfos = {}
			let nodeIDs: [String] = self.nodeDelegators.keys

			let preTotalCommitted = self.totalCommitted
			let preTotalStaked = self.totalStaked
			let preTotalUnstaking = self.totalUnstaking
			let preTotalRewarded = self.totalRewarded
			let preTotalUnstaked = self.totalUnstaked
			let preTotalRequestedToUnstake = self.totalRequestedToUnstake
			self.totalCommitted = 0.0
			self.totalStaked = 0.0
			self.totalUnstaking = 0.0
			self.totalRewarded = 0.0
			self.totalUnstaked = 0.0
			self.totalRequestedToUnstake = 0.0

			// TODO 如果400个节点同时存在，这里有out of gas limit的风险
			// 1. 官方的奖励派发不能保障在新epoch到来前
			// 2. 奖励的派发不能保障一次性发放
			for nodeID in nodeIDs {
				let delegatorID = self.nodeDelegators[nodeID]?.id
                let info = FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID!)

				if self.nodeDelegatorInfos.containsKey(nodeID) && self.nodeDelegatorInfos[nodeID]?.tokensStaked! > 0.0 {
					let preReward = self.nodeDelegatorInfos[nodeID]?.tokensRewarded!
					let curReward = info.tokensRewarded
					assert(curReward > preReward, message: "Rewards are not paid on node: ".concat(nodeID))
				}

				self.totalCommitted = self.totalCommitted + info.tokensCommitted
				self.totalStaked = self.totalStaked + info.tokensStaked
				self.totalUnstaking = self.totalUnstaking + info.tokensUnstaking
				self.totalRewarded = self.totalRewarded + info.tokensRewarded
				self.totalUnstaked = self.totalUnstaked + info.tokensUnstaked
				self.totalRequestedToUnstake = self.totalRequestedToUnstake + info.tokensRequestedToUnstake

				newDelegatorInfos[nodeID] = info
			}

			assert(preTotalStaked + preTotalCommitted - preTotalRequestedToUnstake == self.totalStaked, message: "Data sync error: staked expect ".concat((preTotalStaked + preTotalCommitted - preTotalRequestedToUnstake).toString()).concat(" got ").concat(self.totalStaked.toString()))
			assert(preTotalRequestedToUnstake == self.totalUnstaking, message: "Data sync error: unstaking")

			// TODO 在上个epoch的末期的提交会被放到当前的committed中

			//
			self.currentEpoch = FlowEpoch.currentEpochCounter
			//
			self.nodeDelegatorInfos = newDelegatorInfos

			// 新产生的rewards
			// TODO 这里会是负数吗？ 如果外部操作都正确的同步更新totalRewards
			let rewardDelta = self.totalRewarded - preTotalRewarded

			var rewardPerToken = 0.0
			if preTotalStaked > 0.0 {
				rewardPerToken = rewardDelta / preTotalStaked
			}
			

			self.currentRewardIndex = self.currentRewardIndex + rewardPerToken
			// 记录历史rewardIndex
			self.historyRewardIndex[self.currentEpoch] = self.currentRewardIndex
		}
	}

	access(self) fun borrowDelegator(_ nodeID: String): &FlowIDTableStaking.NodeDelegator? {
		if self.nodeDelegators[nodeID] != nil {
			let delegatorRef = (&self.nodeDelegators[nodeID] as &FlowIDTableStaking.NodeDelegator?)!
			return delegatorRef
		} else {
			return nil
		}
	}

	pub fun getRewardIndex(epoch: UInt64): UFix64 {
		return self.historyRewardIndex[epoch]!
	}

	pub fun getCurrentRewardIndex(epoch: UInt64): UFix64 {
		pre {
			FlowEpoch.currentEpochCounter == self.currentEpoch: "Data is out of date"
		}
		return self.historyRewardIndex[self.currentEpoch]!
	}

	pub fun isNodeDelegated(_ nodeID: String): Bool {
		return self.nodeDelegators.keys.contains(nodeID)
	}

	
	pub resource LiquidStakingPublic: LiquidStakingInterfaces.LiquidStakingPublic {
		pub fun getCurrentEpoch(): UInt64 {
			return LiquidStaking.currentEpoch
		}

		pub fun getRewardIndex(epoch: UInt64): UFix64 {
			return LiquidStaking.historyRewardIndex[epoch]!
		}

		pub fun getCurrentRewardIndex(epoch: UInt64): UFix64 {
			pre {
				FlowEpoch.currentEpochCounter == LiquidStaking.currentEpoch: "Out of date"
			}
			return LiquidStaking.historyRewardIndex[LiquidStaking.currentEpoch]!
		}

		// Flow的epoch周期分为三部分
		// 在auction期间可以正常质押
		// 在另外两个周期的质押会被延后	
		pub fun getEpochToCommitStaking(): UInt64 {
			let currentEpochCounter = FlowEpoch.currentEpochCounter
			if (FlowIDTableStaking.stakingEnabled()) {
				return currentEpochCounter
			} else {
				return currentEpochCounter + 1
			}
		}


	}

	pub resource Admin {
		pub fun registerDelegator(nodeID: String) {
			LiquidStaking.registerDelegator(nodeID)
		}
	}

	init() {
		self.currentEpoch = FlowEpoch.currentEpochCounter
		self.currentRewardIndex = 0.0
		
		self.totalCommitted = 0.0
		self.totalStaked = 0.0
		self.totalUnstaking = 0.0
		self.totalRewarded = 0.0
		self.totalUnstaked = 0.0
		self.totalRequestedToUnstake = 0.0


		self.nodeDelegators <- {}
		self.nodeDelegatorInfos = {}
		self.historyRewardIndex = {}
		//self.userInfos = {}

		

		self.account.save(<-create Admin(), to: /storage/stakingAdmin)

		// create stFlow minter
		let stFlowAdmin = self.account.borrow<&stFlowToken.Administrator>(from: /storage/stFlowTokenAdmin)!
		self.stFlowMinter <- stFlowAdmin.createNewMinter(allowedAmount: UFix64.max)

		// 
		self.account.save(<-create LiquidStakingPublic(), to: /storage/liquidStakingPublic)
		self.account.unlink(LiquidStakingConfig.LiquidStakingPublicPath)
		self.account.link<&{LiquidStakingInterfaces.LiquidStakingPublic}>(LiquidStakingConfig.LiquidStakingPublicPath, target: /storage/liquidStakingPublic)
	}

}