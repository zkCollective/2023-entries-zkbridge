pragma circom 2.0.2;

include "../../circuits/bigint.circom";

component main {public [in, p]} = BigSqrtModP(3, 2);