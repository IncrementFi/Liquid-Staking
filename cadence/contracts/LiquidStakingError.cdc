/**

# Common liquid staking errors

# Author: Increment Labs

*/
pub contract LiquidStakingError {

    pub enum ErrorCode: UInt8 {
        pub case NO_ERROR
        pub case INVALID_PARAMETERS
        pub case REWARD_NOT_PAID
    }

    pub fun ErrorEncode(msg: String, err: ErrorCode): String {
        return "[IncLiquidStakingErrorMsg:".concat(msg).concat("]").concat(
               "[IncLiquidStakingErrorCode:").concat(err.rawValue.toString()).concat("]")
    }

    init() {
    }
}
