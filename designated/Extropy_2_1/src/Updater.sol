// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Verifier.sol";
import "./BatchVerifier.sol";

struct Header {
    uint64 slot;
    uint64 proposerIndex;
    bytes32 parentRoot;
    bytes32 stateRoot;
    bytes32 bodyRoot;
    bool isValid;
}

// from https://github.com/ethereum/consensus-specs/blob/dev/specs/altair/light-client/sync-protocol.md#lightclientstore
struct LCS {
    // Sync committees corresponding to the finalized header
    syncCommittee currentSyncCommittee;
    syncCommittee nextSyncCommittee;
    // Finalised Header
    Header finalisedHeader;
    // Most recent available reasonably-safe header
    Header optimisticHeader;
    //Max number of active participants
    //in a sync committee (used to calculate safety threshold)
    uint64 previousMaxActiveParticipants;
    uint64 currentMaxActiveParticipants;
}

struct LightClientUpdate {
    Header finalizedHeader;
    syncCommittee nextSyncCommitteeRoot;
    BLSSignature signature;
}

struct BLSSignature {
    uint64 participation;
    Pi proof; // we ignore input
}

struct syncCommittee {
    bytes32 root;
    uint64 numberMembers;
}

struct Pi {
    uint[2] a;
    uint[2][2] b;
    uint[2] c;
    uint[2] input;
}

struct HeaderReturn {
    Header header;
    LCS lcs;
    bool found;
}

// bytes32  constant GENESIS_VALIDATORS_ROOT;
uint256 constant GENESIS_TIME = 1606824000;
uint256 constant SECONDS_PER_SLOT = 12;
uint256 constant SLOTS_PER_SYNC_COMMITTEE_PERIOD = 256 * 32;

contract Updater {
    mapping(bytes32 stateRoot => Header header) headerDAG;
    mapping(uint256 => bytes32) public syncCommitteeRootByPeriod;
    LCS private lcs;

    Verifier private verifier;
    BatchVerifier private batchVerifier;

    constructor(Verifier _verifier, BatchVerifier _batchVerifier) {
        verifier = _verifier;
        batchVerifier = _batchVerifier;

        Header memory header = Header({
            slot: 1,
            proposerIndex: 1,
            parentRoot: bytes32(
                0x0000000000000000000000000000000000000000000000000000000000000000
            ),
            stateRoot: bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            ),
            bodyRoot: bytes32(
                0x1111111111111111111111111111111111111111111111111111111111111111
            ),
            isValid: true
        });
        _addHeader(header);
    }

    function headerUpdate(
        Pi calldata proof,
        Header calldata blockHeader,
        Header calldata blockHeaderPrev
    ) public returns (bool) {
        require(
            blockHeader.parentRoot == blockHeaderPrev.stateRoot,
            "Blocks are not subsequent"
        );

        if (!headerDAG[blockHeader.parentRoot].isValid) {
            return false;
        }

        if (!verifier.verifyProof(proof.a, proof.b, proof.c, proof.input)) {
            return false;
        }

        // update LCS
        _updateLCS(blockHeader);

        _addHeader(blockHeader);
        return true;
    }

    function _updateLCS(Header calldata blockHeader) private {
        // update LCS
        uint64 slot = getCurrentSlot();
        uint64 period = getSyncCommitteePeriodFromSlot(slot);
        lcs = LCS({
            currentSyncCommittee: _getSyncCommitteeAtPeriod(period),
            nextSyncCommittee: _getSyncCommitteeAtPeriod(0),
            finalisedHeader: blockHeader,
            optimisticHeader: blockHeader,
            previousMaxActiveParticipants: 1,
            currentMaxActiveParticipants: 1
        });
    }

    function batchHeaderUpdate(
        Pi calldata proof,
        Header[] calldata headers
    ) public returns (bool) {
        if (!batchVerifier.verifyProof(proof.a, proof.b, proof.c, proof.input)) {
            return false;
        }

        uint numHeaders = headers.length;
        _updateLCS(headers[numHeaders - 1]);
        // add valid headers
        for (uint ii = 0; ii < numHeaders; ii++) {
            _addHeader(headers[ii]);
        }
        return true;
    }

    function getHeader(
        bytes32 stateRoot
    ) public view returns (HeaderReturn memory) {
        Header memory header = headerDAG[stateRoot];
        bool found = false;

        if (header.isValid) {
            found = true;
        }

        HeaderReturn memory headerReturn = HeaderReturn({
            header: header,
            lcs: lcs,
            found: found
        });

        return headerReturn;
    }

    function _getSyncCommitteeAtPeriod(
        uint64 period
    ) internal view returns (syncCommittee memory) {
        // return dummy value for now
        return
            syncCommittee({
                root: 0x2909300d4222b4b79b94c2d88b1d625e4d7c9a483a5108afaed1699f7547ceb3,
                numberMembers: 1
            });
    }

    function _addHeader(Header memory header) internal {
        headerDAG[header.stateRoot] = header;
    }

    function setSyncCommitteeRoot(uint64 period, bytes32 root) public {
        syncCommitteeRootByPeriod[period] = root;
    }

    function getCurrentSlot() public view returns (uint64) {
        return uint64((block.timestamp - GENESIS_TIME) / SECONDS_PER_SLOT);
    }

    function getSyncCommitteePeriodFromSlot(
        uint64 slot
    ) public pure returns (uint64) {
        return uint64(slot / SLOTS_PER_SYNC_COMMITTEE_PERIOD);
    }
}
