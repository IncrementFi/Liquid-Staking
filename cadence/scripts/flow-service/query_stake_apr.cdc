import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

pub fun main(): [AnyStruct] {
    var totalStaked = FlowIDTableStaking.getTotalStaked()
    var totalPayed = FlowIDTableStaking.getEpochTokenPayout()
    totalStaked = 718993681.55853413
    totalPayed = 1288436.00000000
    // apr return totalPay/totalStaked*100.0/7.0*365.0 * 0.92
    return [totalStaked, totalPayed, (totalPayed/totalStaked*2514.6*0.92)]
    //return [totalStaked, totalPayed]
}