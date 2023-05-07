## ERecover for ECDSA

The final implementation consists of pure Circom implementation of `ERecover` calcuation and a check on the resulted pubkey.

Mainly it implements the logic of recovring public key from r, s, v and then use constraints to verify that public key against the signature. This is because the logic of recoving the public key is more costly than the logic to verify it against the signature.

The main template is `ECDSARecover` in `ecdsa.circom`.

### Build

```
npm i
```

### Test

```
npm test -- --grep "ECDSARecover"
```
