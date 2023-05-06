# zkBridge


![](https://zk-hacking.org/assets/img/zkbridge_layers.png?raw=true)


Designated task 2.1 Updater contract for Ethereum and Gnosis
- SSZ encoding of block header
- Batched proof generation/verification and skipping block policy
    - Batched proof generation aims to generate multiple block header proofs to
    reduce the proof verification cost. It will merge multiple block header verifications
    into one giant proof.
    - The Skipping Block Method is a feature of the light client. Since the sync
    committee changes every 27.3 hours, we do not need to verify intermediate
    unused blocks. We only need to verify two types of blocks:
        - Those requested by the user
        - Those that handle the sync committee change
- Sync committee set update and maintenance



## References
zkBridge white [paper](https://arxiv.org/pdf/2210.00264.pdf)

SSZ [Encoding](https://ethereum.org/en/developers/docs/data-structures-and-encoding/ssz/)

SSZ circuit [example](https://github.com/succinctlabs/eth-proof-of-consensus/blob/main/circuits/circuits/simple_serialize.circom)

Light client [spec](https://github.com/ethereum/consensus-specs/blob/dev/specs/altair/light-client/sync-protocol.md)

