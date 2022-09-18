transaction() {
    prepare(userAccount: AuthAccount) {
        var index = 0
        while (index < 15) {
            userAccount.keys.add(publicKey: PublicKey(
                publicKey: "95efe052cc2e1be2162cb4c273ab86a4602369536fac60e835c63ee5fc856ad7f6f4d17eb505af54482caac0addeb9b2b24e7b44eb79cb02e19be106c1cbfd4f".decodeHex(),
                signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1), hashAlgorithm: HashAlgorithm.SHA3_256, weight: 1000.0)
            index = index + 1
        }    
    }
}
 