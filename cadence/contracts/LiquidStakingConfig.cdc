/**

# Common liquid staking config

# Author: Increment Labs

*/
pub contract LiquidStakingConfig {
    
	pub var LiquidStakingPublicPath: PublicPath

	
    init() {
        self.LiquidStakingPublicPath = /public/liquidStakingPublic
    }
}