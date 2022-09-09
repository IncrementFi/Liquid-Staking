import FungibleToken from "../../contracts/standard/FungibleToken.cdc"
import FlowIDTableStaking from "../../contracts/standard/emulator/FlowIDTableStaking.cdc"

pub fun main(): Bool {
     // verify signature
    let publicKey = PublicKey(
        publicKey: "dddd52da46af51203d5101de0214c2f0a22d97bcc0c824f6a2dfe91baa4e94465d2f9ffd8180d84fcfa72dc78cdebe3842a7b1a843e76444d81bdbf77ff29be1".decodeHex(),
        signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
    )

    let data = "0xe91802602104a325"
        .concat(":")
        .concat("525450071")
        .concat(":")
        .concat("0x24fdd433d269ba38")
        .concat(":")
        .concat("9.00000000")
        .concat(":")
        .concat("1662545537")
    let signature = "8be29ba1974f63cecd1cdb1091470712b33c90bdfdf9ff0b7c4f464ffc3a8a0070b0f8d1091ce84d84a65f993463a535a30b6dda5e4a594b6538f83cd2803128"
    let isValid = publicKey.verify(
        signature: signature.decodeHex(),
        signedData: data.utf8,
        domainSeparationTag: "FLOW-V0.0-user",
        hashAlgorithm: HashAlgorithm.SHA3_256
    )
    return isValid
}