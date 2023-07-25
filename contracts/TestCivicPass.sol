// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@identity.com/gateway-protocol-eth/contracts/Gated.sol";

contract TestCivicPass is Gated {
    constructor(
        address gatewayTokenContract,
        uint256 gatekeeperNetwork
    ) Gated(gatewayTokenContract, gatekeeperNetwork) {}

    function checkCivicPass() external view gated returns (bool) {
        return true;
    }
}
