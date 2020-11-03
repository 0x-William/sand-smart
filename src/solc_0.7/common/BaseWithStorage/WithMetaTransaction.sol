//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.1;

import "./WithAdmin.sol";

contract WithMetaTransaction is WithAdmin {
    uint8 internal constant METATX_SANDBOX = 1;
    uint8 internal constant METATX_2771 = 2;
    mapping(address => uint8) internal _metaTransactionContracts;

    /// @dev emiited when a meta transaction processor is enabled/disabled
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param processorType set the metaTransactionProcessor type
    event MetaTransactionProcessor(address metaTransactionProcessor, uint8 processorType);

    /// @dev Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param processorType set the metaTransactionProcessor type
    function setMetaTransactionProcessor(address metaTransactionProcessor, uint8 processorType) public {
        require(msg.sender == _admin, "only admin can setup metaTransactionProcessors");
        _setMetaTransactionProcessor(metaTransactionProcessor, processorType);
    }

    function _setMetaTransactionProcessor(address metaTransactionProcessor, uint8 processorType) internal {
        _metaTransactionContracts[metaTransactionProcessor] = processorType;
        emit MetaTransactionProcessor(metaTransactionProcessor, processorType);
    }

    /// @dev check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return the type of metatx processor (0 for none)
    function getMetaTransactionProcessorType(address who) external view returns (uint8) {
        return _metaTransactionContracts[who];
    }

    // --------------------------------------------------------------------------------
    // EIP-2771 Meta Transaction Recipient
    // --------------------------------------------------------------------------------

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return _metaTransactionContracts[forwarder] == METATX_2771;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address payable ret) {
        if (isTrustedForwarder(msg.sender)) {
            return _forceMsgSender();
        } else {
            return msg.sender;
        }
    }

    function _forceMsgSender() internal view virtual returns (address payable ret) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ret := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }
}
