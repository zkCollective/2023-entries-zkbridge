# Overview

We worked on the zk bridge track "Category6. Defense in Depth"

[PR contribution to Hashi](https://github.com/gnosis/hashi/pull/11)

## Problem

Currently, there is no way for L2s to access L1 state in a _trustless, cheap and easy way_. One option is to use arbitrary messaging bridges to send over the L1 state, but in this case you need to rely on the honesty of the messenger. Another option is to set up a specific purpose bridge (think ERC20 or ERC721 token bridge) so that you don't need to trust the messenger anymore. But this is not generalizable and costly since you need to create a bridge for every single purpose.

So our question was, is there a better way to send over L1 state to L2s?

## Our approach

Instead of creating an entirely new system from scratch, we took advantage of two existing systems to create a solution to this problem. We were inspired by the Hashi team ([ethresearch post](https://ethresear.ch/t/hashi-a-principled-approach-to-bridges/14725/1), [presentation](https://docs.google.com/presentation/d/1yMdO179XFJeeryIqsJg8L4RewH8jaA_p97iCO-vl9mY/edit#slide=id.g21cefba53b5_0_148)) to combine two existing systems to create a solution.

One is [Hashi](https://github.com/gnosis/hashi), which is a system that provides additive security for bridge systems. Essentially, it improves security by allowing L2 protocols to not rely on a single bridge system. Under the hood, it is connected to multiple bridges deployed on L2 and provide aggregate L1 block hash data to L2 protocols. As a result, L2 protocols that rely on a bridge system can avoid being hacked when a single bridge is compromised.

Another is [Axiom](https://www.axiom.xyz/), which enables accessing any historic state on-chain via smart contracts. Storing historic states requires a lot of storage, so it's normally unaffordable on-chain, but Axiom leverages ZK proofs to make this cheap. One thing to point out is that Axiom is currently intended to be used only on L1, but the system is modular so we were able to think about porting a part of it on L2.

## Solution

> Axiom ✍️ + Hashi 橋 => L1StateOracle (Time Travel 🚀 L1 state on L2)

Our approach is to take the proof module of Axiom and to integrate it with Hashi. Below you can compare our architecture with Axiom's existing architecture.

### Axiom Architecture

<img src=https://i.imgur.com/iQzJbgU.png width="600">

### L1StateOracle Architecture

<img src=https://i.imgur.com/pqEHWBE.png width="600">

As you can see in the flow chart above, we created new `AxiomStorageProof` and `AxiomProofVerifier` contracts and deployed them on L2.

Once a user creates a storage proof using [Axiom's backend](https://demo.axiom.xyz/custom), it can send the proof to the L2 contract, which will verify the block hash used in the proof against Hashi's `getHash` function.

When the ZK proof itself is also verified via the `AxiomProofVerifier`, we can safely store the storage proof on-chain, and _voilà_! **Any L2 protocol can confidently use the attested storage data without worrying about a single bridge being compromised.**

# A Build and Run Guide

- Fork the following [PR codebase](https://github.com/gnosis/hashi/pull/11)
- Uncomment the following code in `hardhat.config.ts`:

```
      // Used for testing axiom
      // forking: {
      //   url: getChainConfig("mainnet").url,
      //   // block number of attestation block
      //   blockNumber: 10000000,
      // },
      ...
      // tests: "./test_axiom",
```

- Run `yarn` and `yarn test`

# Additional Resources

- [Presentation](./L1StateOracle.pdf)
- https://hackmd.io/@mellowcroc/rJDwFTe7h
