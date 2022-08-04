import FungibleToken from "./standard/FungibleToken.cdc"
import FlowToken from "./standard/FlowToken.cdc"
import FlowIDTableStaking from "./flow/FlowIDTableStaking.cdc"
import stFlowToken from "./stFlowToken.cdc"


pub contract stFlowStaking {
	
	pub var rewardAccumulated: UFix64
	

	access(self) var nodeDelegators: @{String: FlowIDTableStaking.NodeDelegator}
	access(self) var stFlowMinter: @stFlowToken.Minter
	access(self) var userInfos: {Address: UserInfo}

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
			self.ifNodeDelegated(nodeID) == false: "Cannot register a delegator for a node that is already being delegated to"
		}

		let nodeDelegator <- FlowIDTableStaking.registerNewDelegator(nodeID: nodeID)

		emit RegisterNewDelegator(nodeID: nodeDelegator.nodeID, delegatorID: nodeDelegator.id)

		self.nodeDelegators[nodeDelegator.nodeID] <-! nodeDelegator
	}

	// 用户stake进来的时候，会mint出同等量的stFlow
	// 记录下这个stFlow的 RewardAccumulated
	// ?? 新生成的stflow vault会跟用户本地的merge?
	// ？？ 有多少是还未被质押的？
	pub fun stake(userAddr: Address, nodeID: String, stakeVault: @FlowToken.Vault): @stFlowToken.Vault {
		pre {
			stakeVault.balance > 0.0: "Stake amount must be greater than 0"
		}
		// new stake node
		if self.ifNodeDelegated(nodeID) == false {
			self.registerDelegator(nodeID)
		}

		let stakeAmount = stakeVault.balance
		let nodeDelegator = self.borrowDelegator(nodeID)!

		// On stake auction stage, committed tokens will be staked in the next epoch.
		if (FlowIDTableStaking.stakingEnabled()) {
			// Delegate into committed vault of FlowIDTableStaking
			nodeDelegator.delegateNewTokens(from: <-stakeVault)
			// Mint stFlow
			let stFlowVault <- self.stFlowMinter.mintTokens(amount: stakeAmount)

			return <-stFlowVault
		}
		// During auction stage ends and the next epoch does not start, tokens will be held and committed until the next epoch.
		else {
			// TODO
			destroy stakeVault
			assert(false, message: "not in auction stage")

			return <-self.stFlowMinter.mintTokens(amount: 0.0)
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

	// 得到当前质押所属的epochCounter，如果auction已经结束，则自动归为下一个epoch
	pub fun getUnlockedEpochCounter() {
		
	}

	pub fun ifNodeDelegated(_ nodeID: String): Bool {
		return self.nodeDelegators.keys.contains(nodeID)
	}

	pub resource Admin {
		pub fun registerDelegator(nodeID: String) {
			stFlowStaking.registerDelegator(nodeID)
		}
	}

	init() {
		self.rewardAccumulated = 0.0
		self.nodeDelegators <- {}
		self.userInfos = {}
		

		self.account.save(<-create Admin(), to: /storage/stakingAdmin)

		// create stFlow minter
		let stFlowAdmin = self.account.borrow<&stFlowToken.Administrator>(from: /storage/stFlowTokenAdmin)!
		self.stFlowMinter <- stFlowAdmin.createNewMinter(allowedAmount: UFix64.max)
		

	}
	
	// 有多少是立马可以unstake的？
	// 有多少是锁住的需要被记录下周提取的？
	pub fun unstake() {

	}
	// ?? 单独claim奖励？ 直接claim成Flow
	pub fun claim() {

	}


}