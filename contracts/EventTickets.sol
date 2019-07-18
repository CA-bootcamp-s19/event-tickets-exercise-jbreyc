pragma solidity ^0.5.0;

/*
    The EventTickets contract keeps track of the details and ticket sales of one event.
 */

contract EventTickets {
    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */
    address payable public owner;

    // Fixed ticket price.
    uint256 TICKET_PRICE = 100 wei;

    /*
        Create a struct called "Event".
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint256 totalTickets;
        uint256 sales;
        mapping(address => uint256) buyers;
        bool isOpen;
    }

    Event myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide information about the contract owner and the balance transferred to them.
    */
    event LogBuyTickets(address indexed buyer, uint256 numOfTickets);
    event LogGetRefund(address indexed buyer, uint256 numOfTickets);
    event LogEndSale(address indexed owner, uint256 balance);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "\u274C Only the contract owner can call this function"
        );
        _;
    }

    // Throws an error if the event is not in an open state.
    modifier eventIsOpen() {
        require(myEvent.isOpen, "\u274C The event is closed");
        _;
    }

    // Throws an error if the payment submitted is less than what is required to pay for the tickets.
    modifier paidEnough(uint256 numOfTickets) {
        require(
            msg.value >= numOfTickets * TICKET_PRICE,
            "\u274C The amount paid is not sufficient to purchase all the tickets."
        );
        _;
    }

    // Throws an error if the number of tickets in stock is less than the amount requested for purchase.
    modifier sufficientStock(uint256 numOfTickets) {
        require(
            myEvent.totalTickets - myEvent.sales >= numOfTickets,
            "The number of tickets available for sale is less than the number requested."
        );
        _;
    }

    // Returns ether paid in excess by the buyer.
    modifier refundExcess(uint256 numOfTickets) {
        _;
        uint256 paidInExcess = msg.value - numOfTickets * TICKET_PRICE;
        if (paidInExcess > 0) {
            msg.sender.transfer(paidInExcess);
        }
    }

    // Checks that the caller is a ticker holder
    modifier verifyCaller() {
        require(
            myEvent.buyers[msg.sender] != 0,
            "The caller did not purchase any event tickets."
        );
        _;
    }
    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor(
        string memory _description,
        string memory _url,
        uint256 _totalTickets
    ) public {
        owner = msg.sender;

        myEvent.description = _description;
        myEvent.website = _url;
        myEvent.totalTickets = _totalTickets;
        myEvent.sales = 0;
        myEvent.isOpen = true;
    }
    /*
        Define a function called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent()
        public
        view
        returns (
            string memory description,
            string memory website,
            uint256 totalTickets,
            uint256 sales,
            bool isOpen
        )
    {
        description = myEvent.description;
        website = myEvent.website;
        totalTickets = myEvent.totalTickets;
        sales = myEvent.sales;
        isOpen = myEvent.isOpen;
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address buyer) public view returns (uint256) {
        return myEvent.buyers[buyer];
    }

    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */
    function buyTickets(uint256 numOfTickets)
        public
        payable
        eventIsOpen()
        sufficientStock(numOfTickets)
        paidEnough(numOfTickets)
        refundExcess(numOfTickets)
        returns (bool)
    {
        myEvent.buyers[msg.sender] = numOfTickets;
        myEvent.sales += numOfTickets;

        emit LogBuyTickets(msg.sender, numOfTickets);
        return true;
    }
    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */

    function getRefund() public verifyCaller() returns (bool) {
        uint256 ticketsToRefund = myEvent.buyers[msg.sender];
        uint256 amountToRefund = ticketsToRefund * TICKET_PRICE;

        myEvent.buyers[msg.sender] = 0;
        myEvent.sales -= ticketsToRefund;
        msg.sender.transfer(amountToRefund);

        emit LogGetRefund(msg.sender, ticketsToRefund);
        return true;
    }

    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */
    function endSale() public onlyOwner() eventIsOpen() returns (bool) {
        myEvent.isOpen = false;
        msg.sender.transfer(address(this).balance);

        emit LogEndSale(msg.sender, address(this).balance);
        return true;
    }
}
