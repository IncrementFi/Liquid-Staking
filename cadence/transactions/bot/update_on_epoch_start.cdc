import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction(start: Int, end: Int) {
    prepare(botAcct: AuthAccount) {
        log("---------> bot: update")
        DelegatorManager.collectDelegatorsOnEpochStart(startIndex: start, endIndex: end)
    }
}