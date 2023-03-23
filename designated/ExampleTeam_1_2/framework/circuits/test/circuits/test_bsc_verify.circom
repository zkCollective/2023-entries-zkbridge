include "../../circuits/bsc/bsc_verify.circom";

component main {public [r, s, msghash, pubkey]} = BscVerify(64, 4);
