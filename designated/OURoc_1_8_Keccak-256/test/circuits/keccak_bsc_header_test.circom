pragma circom 2.0.0;

include "../../circuits/keccak.circom";

component main = KeccakV(1075*8, 256);
