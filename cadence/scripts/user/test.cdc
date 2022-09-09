import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

pub struct AdminSignedData {
    pub let externalID: String
    pub let priceType: String
    pub let primarySaleAddress: Address
    pub let purchaserAddress: Address
    pub let assetIDs: [UInt64]
    pub let expiration: UInt64 // unix timestamp

    init(externalID: String, primarySaleAddress: Address, purchaserAddress: Address, assetIDs: [UInt64], priceType: String, expiration: UInt64){
        self.externalID = externalID
        self.primarySaleAddress = primarySaleAddress
        self.purchaserAddress = purchaserAddress
        self.assetIDs = assetIDs
        self.priceType = priceType
        self.expiration = expiration
    }

    pub fun toString(): String {
        var assetIDs = ""
        var i = 0
        while (i < self.assetIDs.length) {
            if (i > 0) {
                assetIDs = assetIDs.concat(",")
            }
            assetIDs = assetIDs.concat(self.assetIDs[i].toString())
            i = i + 1
        }
        return self.externalID.concat(":")
            .concat(self.primarySaleAddress.toString()).concat(":")
            .concat(self.purchaserAddress.toString()).concat(":")
            .concat(assetIDs).concat(":")
            .concat(self.priceType).concat(":")
            .concat(self.expiration.toString())
    }
}

pub fun main(): Bool {
    let data = AdminSignedData(
        externalID: "dimensionx", primarySaleAddress: 0xc9be8dab3f45c748, purchaserAddress: 0x28b8b59faaf50b5e, assetIDs: [2969], priceType: "preSale", expiration: 1662451634
    )
    let publicKey = PublicKey(
        publicKey: "172cf058deda8539f82d0c536760dd7be8b11ee634269b49ab4c5f925170b0d48fe2a4e22557dddb470502834d72bec73dfeb5eb81becc340fc950ec892d150f".decodeHex(),
        signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
    )
    let sig = "b9a5de5320faa4d337d521b1d5a11bd3578d9aa969bd3e15bea51282ab29a310970b7515e624eb08e8d921a97b3760752b40044daa17a7d865ba19ea2292e644"

    return publicKey.verify(
        signature: sig.decodeHex(),
        signedData: data.toString().utf8,
        domainSeparationTag: "FLOW-V0.0-user",
        hashAlgorithm: HashAlgorithm.SHA3_256
    )
}