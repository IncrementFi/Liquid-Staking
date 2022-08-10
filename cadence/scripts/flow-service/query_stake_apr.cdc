import FlowIDTableStaking from "../../contracts/flow/FlowIDTableStaking.cdc"

pub fun main(): [AnyStruct] {
    let totalStaked = FlowIDTableStaking.getTotalStaked()
    let totalPayed = FlowIDTableStaking.getEpochTokenPayout()
    
    // apr return totalPay/totalStaked*100.0/7.0*365.0 * 0.92
    //return [totalStaked, totalPayed, (totalPayed/totalStaked*1614.6*0.92)]
    return [totalStaked, totalPayed]
}