import DelegatorManager from "../../contracts/DelegatorManager.cdc"

transaction() {
    prepare(nodeMgrAcct: AuthAccount) {
        log("---------> node: set approved list")
        let adminRef = nodeMgrAcct.borrow<&DelegatorManager.Admin>(from: DelegatorManager.adminPath)!
        let ids: {String: UFix64} = {
            "4d61636b656e7a6965204b696572616e00f6f67701306474b17e48210151b8fd": 1.0,
            "4d616b73205061776c616b00fe71b0a48963807956690ae753cf19a750e3eb90": 1.0,
            "52616d74696e20536572616a00661071ba7fd92f29b345ea3252e48d20c3a434": 1.0,
            "42656e6a616d696e2056616e204d657465720026d6a7262c8d90e710bcebc3c3": 1.0,
            "4c61796e65204c616672616e6365007442b7de3e1dc4c8b35545676fc554b343": 1.0
        }
        adminRef.setApprovedNodeIDList(nodeIDs: ids, reservedNodeIDToStake: "4d61636b656e7a6965204b696572616e00f6f67701306474b17e48210151b8fd")

        adminRef.registerNewDelegator(nodeID: "4d61636b656e7a6965204b696572616e00f6f67701306474b17e48210151b8fd")
        adminRef.registerNewDelegator(nodeID: "4d616b73205061776c616b00fe71b0a48963807956690ae753cf19a750e3eb90")
        adminRef.registerNewDelegator(nodeID: "52616d74696e20536572616a00661071ba7fd92f29b345ea3252e48d20c3a434")
        adminRef.registerNewDelegator(nodeID: "42656e6a616d696e2056616e204d657465720026d6a7262c8d90e710bcebc3c3")
        adminRef.registerNewDelegator(nodeID: "4c61796e65204c616672616e6365007442b7de3e1dc4c8b35545676fc554b343")
    }
}