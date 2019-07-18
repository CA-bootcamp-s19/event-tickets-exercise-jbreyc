pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/EventTickets.sol";
import "../contracts/EventTicketsV2.sol";

contract TestEventTicket {

    // Let's fund the contract to test purchases
    uint public initialBalance = 1 ether;

    uint256 constant TICKET_PRICE = 100 wei;

    struct EventStub {
        string desc;
        string web;
        uint totalTickets;

    }
    
    EventStub event1 = EventStub("event 1 description", "URL 1", 100 );
    EventStub event2 = EventStub("event 2 description", "URL 2", 200 );
    EventStub event3 = EventStub("event 3 description", "URL 3", 300 );

  function testOwner() public {
    EventTickets _event = EventTickets(DeployedAddresses.EventTickets());
    Assert.equal(_event.owner(), msg.sender, "the deploying address should be the owner");
  }

    function testOpenSalesAtCreation() public {
        EventTickets _event = new EventTickets(event1.desc, event1.web, event1.totalTickets);
        (string memory desc, string memory web, uint totalTickets, uint sales, bool isOpen) = _event.readEvent();
        Assert.equal(isOpen, true, "the event should be open");
    }

    function testEventDataCorrect() public {
        EventTickets _event = new EventTickets(event1.desc, event1.web, event1.totalTickets);
        (string memory desc, string memory web, uint totalTickets, uint sales, bool isOpen) = _event.readEvent();
        Assert.equal(desc, event1.desc, "Descriptions should match");
        Assert.equal(web, event1.web, "Webs should match");
        Assert.equal(totalTickets, event1.totalTickets, "Total Tickets should match");
        Assert.equal(sales, 0, "Sales should match");
    }

    function testVanillaTicketPurchase() public payable {
        EventTickets _event = new EventTickets(event1.desc, event1.web, event1.totalTickets);
        _event.buyTickets.value(TICKET_PRICE)(1);
        (string memory desc, string memory web, uint totalTickets, uint sales, bool isOpen) = _event.readEvent();
        Assert.equal(sales, 1, "Number of tickets sold should match after a ticket purchase");
    }

    function testLowPriceTicketPurchase() public payable {
        EventTickets _event = new EventTickets(event1.desc, event1.web, event1.totalTickets);
        (bool success, bytes memory returnData) = address(_event).call.value(TICKET_PRICE - 10 wei)(abi.encodeWithSignature("buyTickets(uint256)", 1));
        
        Assert.isFalse(success, "Should not be possible to haggle on a ticket purchase");
    }

    function testEnoughStockTicketPurchase() public payable {
        EventTickets _event = new EventTickets(event1.desc, event1.web, event1.totalTickets);
        _event.buyTickets.value(TICKET_PRICE*90)(90);
        (bool success, bytes memory returnData) = address(_event).call.value(TICKET_PRICE * 11)(abi.encodeWithSignature("buyTickets(uint256)", 11));
        
        Assert.isFalse(success, "Should not be possible to buy more tickets than available in stock");
    }

    function testTicketReceived() public payable {
        EventTickets _event = new EventTickets(event1.desc, event1.web, event1.totalTickets);
        _event.buyTickets.value(TICKET_PRICE*2)(2);
        uint tickets = _event.getBuyerTicketCount(address(this));
        Assert.equal(tickets, 2, "The buyer should have the 2 tickets purchased");
    }
}