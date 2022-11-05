// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "./interfaces/OptimisticOracleV2Interface.sol";

// *************************************
// *   Minimum Viable OO Intergration  *
// *************************************

// This contract shows how to get up and running as quickly as posible with UMA's Optimistic Oracle.
// We make a simple price request to the OO and return it to the user.

contract TicketManager {
  // Create an Optimistic oracle instance at the deployed address on Görli.
  OptimisticOracleV2Interface oo = OptimisticOracleV2Interface(0xA5B9d8a0B0Fa04Ba71BDD68069661ED5C0848884);

  // Use the yes no idetifier to ask arbitary questions, such as the weather on a particular day.
  bytes32 identifier = bytes32("VIX");

  // Post the question in ancillary data. Note that this is a simplified form of ancillry data to work as an example. A real
  // world prodition market would use something slightly more complex and would need to conform to a more robust structure.
  bytes ancillaryData = bytes("https://snapshot.org/#/volatilityprotocol.eth/proposal/0xe9a7dc5c9ccab0a1369440fa887bb50672fa80a50e44182f0a170680499bcaa3");

  uint256 requestTime = 0; // Store the request time so we can re-use it later.

  // Submit a data request to the Optimistic oracle.
  function requestData() public {
    requestTime = block.timestamp; // Set the request time to the current block time.
    IERC20 bondCurrency = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); // Use Görli WETH as the bond currency.
    uint256 reward = 0; // Set the reward to 0 (so we dont have to fund it from this contract).

    // Now, make the price request to the Optimistic oracle and set the liveness to 30 so it will settle quickly.
    oo.requestPrice(identifier, requestTime, ancillaryData, bondCurrency, reward);
    oo.setCustomLiveness(identifier, requestTime, ancillaryData, 30);
  }

  // Settle the request once it's gone through the liveness period of 30 seconds. This acts the finalize the voted on price.
  // In a real world use of the Optimistic Oracle this should be longer to give time to disputers to catch bat price proposals.
  function settleRequest() public {
    oo.settle(address(this), identifier, requestTime, ancillaryData);
  }

  // Fetch the resolved price from the Optimistic Oracle that was settled.
  function getSettledData() public view returns (int256) {
    return oo.getRequest(address(this), identifier, requestTime, ancillaryData).resolvedPrice;
  }
}
