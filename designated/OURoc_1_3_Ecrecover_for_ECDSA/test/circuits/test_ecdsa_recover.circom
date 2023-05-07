pragma circom 2.0.2;

include "../../circuits/ecdsa.circom";

component main {public [r, s, v, msghash]} = ECDSARecover(64, 4);
