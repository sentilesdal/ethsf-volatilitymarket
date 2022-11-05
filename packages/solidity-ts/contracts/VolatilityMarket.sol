// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./OptimisticOracleV2Interface.sol";

contract VolatilityMarket{


    OptimisticOracleV2Interface oo = OptimisticOracleV2Interface(0xA5B9d8a0B0Fa04Ba71BDD68069661ED5C0848884);

    // Use the yes no idetifier to ask arbitary questions, such as the weather on a particular day.
    bytes32 identifier = bytes32("VIX");

    // Post the question in ancillary data. Note that this is a simplified form of ancillry data to work as an example. A real
    // world prodition market would use something slightly more complex and would need to conform to a more robust structure.
    bytes ancillaryData = bytes("https://snapshot.org/#/volatilityprotocol.eth/proposal/0xe9a7dc5c9ccab0a1369440fa887bb50672fa80a50e44182f0a170680499bcaa3");

    uint256 requestTime = 0; // Store the request time so we can re-use it later.


    address owner;

    IERC20 public token;

    uint256 disposableFunds = 0;
    uint256 requiredFunds = 1 wei;
    uint blockBuffer = 1 minutes;
    uint ticketCount = 0;

    uint256 ticketCounter = 0;

    struct ticket {
        uint id;
        address owner;
        uint betTime;
        uint verifyTime;
        uint amount;
        bool success;
        bool claimed;
    }

    mapping(uint => ticket) public tickets;

    event TicketCreated(uint id, address user);

    constructor(address _token){
        token = IERC20(_token);
    }

    //functions that will direclty be invoked from the frontend

    function createBet(uint256 amount) public {
        token.transferFrom(msg.sender, address(this), amount);
        uint256 id  = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
        tickets[id]= ticket(id,msg.sender, block.timestamp, block.timestamp, amount, false,false);
        requestData();
        emit TicketCreated(id, msg.sender);
    }


      function verifyBet(uint256 id) public {
        
        ticket storage currentTicket = tickets[id];
        require(msg.sender == currentTicket.owner);
        require(block.timestamp < currentTicket.betTime + blockBuffer);
        currentTicket.verifyTime = block.timestamp;
        requestData();
        currentTicket.verifyTime = block.timestamp;
    }

    //Ticket is redeemed only within the time period
    function redeemTicket(uint id) public {

        ticket storage currentTicket = tickets[id];
        require(block.timestamp > (currentTicket.betTime + blockBuffer));
        require((currentTicket.amount*2) < disposableFunds);

        currentTicket.success = true;
        currentTicket.claimed = true;


    }

    // function verifyData() internal returns (bool) {
    //     return true; 
    // }

   
    // function  collectDeadTickets() internal{
        
    // }

  // Create an Optimistic oracle instance at the deployed address on Görli.

  // Submit a data request to the Optimistic oracle.
  function requestData() public {
    requestTime = block.timestamp; // Set the request time to the current block time.
    uint256 reward = 0; // Set the reward to 0 (so we dont have to fund it from this contract).

    // Now, make the price request to the Optimistic oracle and set the liveness to 30 so it will settle quickly.
    oo.requestPrice(identifier, block.timestamp, ancillaryData, token, reward);
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

