# General Info

The project code is mostly from rainbow bridge hosted by aurora is near foundation, we mainly contribute to reading the codebase of it and remove near related code. (like Borsh serialization).The project hasn't passed all the test cases yet, but we're working on it.

## Website

https://turing-bridge.com/ - Under construction

## Project Team Members:

dev_jsarje
GuanBo
Nooma
StatArbJitsu
Zhejia

# Build and Run Guide

Assuming Rust Installed, if not, you may visit [here](https://www.rust-lang.org/tools/install)

```
cd 2023-entries-zkbridge/designated/TuringBridge_3_1/eth2gnosis/eth_rpc_client
cargo test
```

# Write up

## Structure of the project

The file structure of the project is as follows:

```
├── eth-helper
│   ├── admin-controlled
│   ├── eth-client
│   ├── eth-prover
│   ├── eth-types
│   ├── eth2-client
│   ├── eth2-utility
│   └── eth2_hashing
└── eth2gnosis
    └── eth_rpc_client
```

This project sturucture preserves the extensibility of the original project, and the eth2gnosis folder is the main part of the project. An ideally extended structure of the project is as follows:

```
├── eth-helper
├── eth2gnosis
└── eth2polygon
.
.
.
```

## 1. Core modules explaned

## eth_rpc_client

### beacon_rpc_client.rs

A client for interacting with Ethereum2.0 beacon chain using JSON-RPC calls.

It should get block body, header, light_client_update, slot_number, checkpoint_root, and bootstrap from beacon chain.

A few Collected Function:

- get_beacon_block_body_for_block_id: Fetches the BeaconBlockBody for the given block ID.
- get_beacon_block_header_for_block_id: Fetches the BeaconBlockHeader for the given block ID.
- get_light_client_update: Fetches a LightClientUpdate for the given period. A LightClientUpdate is an object passed over the wire (could be over a p2p network or through a client-server setup) which contains all of the information needed to convince a light client to accept a newer block header. The information included is:

  ```
  class LightClientUpdate(Container):
      # Update beacon block header
      header: BeaconBlockHeader
      # Next sync committee corresponding to the header
      next_sync_committee: SyncCommittee
      next_sync_committee_branch: Vector[Bytes32, floorlog2(NEXT_SYNC_COMMITTEE_INDEX)]
      # Finality proof for the update header
      finality_header: BeaconBlockHeader
      finality_branch: Vector[Bytes32, floorlog2(FINALIZED_ROOT_INDEX)]
      # Sync committee aggregate signature
      sync_committee_bits: Bitvector[SYNC_COMMITTEE_SIZE]
      sync_committee_signature: BLSSignature
      # Fork version for the aggregate signature
      fork_version: Version
  ```

- get_bootstrap: is a function in beacon_rpc_client.rs that fetches a bootstrapping state along with a proof to a trusted block root, which should be acquired through a similar process as a weak subjectivity checkpoint. In other words, it retrieves a LightClientSnapshotWithProof for the given block_root. The function takes a block_root as a parameter and performs an API request to the corresponding endpoint. It then processes the JSON response and returns a LightClientSnapshotWithProof containing the beacon_header, current_sync_committee, and current_sync_committee_branch.

LightClientSnapshot. LightClientSnapshot represents the light client's view of the most recent block header that the light client is convinced is securely part of the chain. The light client stores the header itself, so that the light client can then ask for Merkle branches to authenticate transactions and state against the header. The light client also stores the current and next sync committees, so that it can verify the sync committee signatures of newer proposed headers.

### beacon_block_body_merkle_tree.rs

Functions for creating a Merkle tree from a beacon block body.
There are multiple calls to the tree_hash_root() method in the code provided. This means that each high-level field of the BeaconBlockBody is treated as a separate tree data structure, and its root hash is computed using the tree_hash_root() method. The root hashes of these fields are then used as the leaves of the BeaconBlockBodyMerkleTree, which is another tree data structure. The root hash of the BeaconBlockBodyMerkleTree is then used as the Merkle root of the BeaconBlockBody, which is part of the header of the beacon block. This way, the code creates a hierarchy of trees that can be used to verify and validate the data in the beacon block.

### execution_block_proof.rs

A helper module to generate Ethereum execution block proofs.
An execution_payload is a data structure that contains information about the transactions and state changes.

### light_client_snapshot_with_proof.rs

A module for creating a light client snapshot with a corresponding proof.

## 2. Helper modules explained

## eth-types

### lib.rs

The first file provides the necessary types and data structures for working with the Beacon Chain,

### eth.rs

while the second file implements a light client that can interact with the Beacon Chain

# Reference

```
- [Aurora is Near](https://github.com/aurora-is-near/rainbow-bridge)
- [Ethereum annotated-spec](https://github.com/ethereum/annotated-spec/blob/master/altair/sync-protocol.md#lightclientupdate)

```

# Reflection and Future Plans

We start off with little to no knowledge of the project, and it was fun we get to know the mechanism behind a cross chain bridge. We spent most of the time reading the codebase and trying to extract part and make the most of existing codebase, figuring out what's going on with the Eth2 beacon chain, and also have an informative discussion within the group and with TA (thank you devesh btw)
Our future plan is to fully complete the project and make it work with the test cases.
