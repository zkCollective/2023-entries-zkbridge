pragma solidity 0.8.18;

library Merkle {


function isValidMerkleBranch(
        bytes32 leaf,
        uint256 index,
        bytes32[] memory branch,
        bytes32 root
    ) internal view returns (bool) {
        bytes32 restoredMerkleRoot = restoreMerkleRoot(leaf, index, branch);
        return root == restoredMerkleRoot;
    }

    function restoreMerkleRoot(
		bytes32 leaf,
		uint256 index,
		bytes32[] memory branch
	) internal pure returns (bytes32) {
		bytes32 value = leaf;
		for (uint256 i = 0; i < branch.length; i++) {
			if ((index / (2**i)) % 2 == 1) {
				value = sha256(bytes.concat(branch[i], value));
			} else {
				value = sha256(bytes.concat(value, branch[i]));
			}
		}
		return value;
	}
}