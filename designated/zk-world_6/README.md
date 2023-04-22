# Overview

We worked on the zk bridge track "Category6. Defense in Depth"

[PR contribution to Hashi](https://github.com/gnosis/hashi/pull/11)

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

# Detailed Description

Please refer to the following links for a detailed description

- https://hackmd.io/@mellowcroc/rJDwFTe7h
- [presentation](./L1StateOracle.pdf)
