pragma solidity ^0.5.0;

/*
    The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
*/
contract EventTicketsV2 {
    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;

    // Default ticket price.
    uint256 internal PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint256 internal idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
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

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint256 => Event) private events;

    event LogEventAdded(
        string desc,
        string url,
        uint256 ticketsAvailable,
        uint256 eventId
    );
    event LogBuyTickets(address buyer, uint256 eventId, uint256 numTickets);

    event LogGetRefund(
        address accountRefunded,
        uint256 eventId,
        uint256 numTickets
    );
    event LogEndSale(address owner, uint256 balance, uint256 eventId);

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
    modifier eventIsOpen(uint256 eventId) {
        require(events[eventId].isOpen, "\u274C The event is closed");
        _;
    }

    // Throws an error if the payment submitted is less than what is required to pay for the tickets.
    modifier paidEnough(uint256 numOfTickets) {
        require(
            msg.value >= numOfTickets * PRICE_TICKET,
            "\u274C The amount paid is not sufficient to purchase all the tickets."
        );
        _;
    }

    // Throws an error if the number of tickets in stock is less than the amount requested for purchase.
    modifier sufficientStock(uint256 eventId, uint256 numOfTickets) {
        require(
            (events[eventId].totalTickets - events[eventId].sales) >=
                numOfTickets,
            "The number of tickets available for sale is less than the number requested."
        );
        _;
    }

    // Returns ether paid in excess by the buyer.
    modifier refundExcess(uint256 numOfTickets) {
        _;
        uint256 paidInExcess = msg.value - numOfTickets * PRICE_TICKET;
        if (paidInExcess > 0) {
            msg.sender.transfer(paidInExcess);
        }
    }

    // Checks that the caller is a ticker holder
    modifier verifyCaller(uint256 eventId) {
        require(
            events[eventId].buyers[msg.sender] != 0,
            "The caller did not purchase any event tickets."
        );
        _;
    }

    // Initialise owner and idGenerator.
    constructor() public {
        owner = msg.sender;
        idGenerator = 0;
    }
    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(
        string memory _description,
        string memory _website,
        uint256 _totalTickets
    ) public onlyOwner() returns (uint256) {
        uint256 eventId = idGenerator;
        events[eventId] = Event({
            description: _description,
            website: _website,
            totalTickets: _totalTickets,
            sales: 0,
            isOpen: true
        });

        idGenerator++;
        emit LogEventAdded(_description, _website, _totalTickets, eventId);
        return eventId;
    }
    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint256 eventId)
        public
        view
        returns (
            string memory description,
            string memory url,
            uint256 availableTickets,
            uint256 sales,
            bool isOpen
        )
    {
        Event memory _event = events[eventId];

        description = _event.description;
        url = _event.website;
        availableTickets = _event.totalTickets - _event.sales;
        sales = _event.sales;
        isOpen = _event.isOpen;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint256 eventId, uint256 numOfTickets)
        public
        payable
        eventIsOpen(eventId)
        sufficientStock(eventId, numOfTickets)
        paidEnough(numOfTickets)
        refundExcess(numOfTickets)
        returns (bool)
    {
        Event storage _event = events[eventId];

        _event.buyers[msg.sender] = numOfTickets;
        _event.sales += numOfTickets;

        emit LogBuyTickets(msg.sender, eventId, numOfTickets);
        return true;
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint256 eventId)
        public
        verifyCaller(eventId)
        returns (bool)
    {
        Event storage _event = events[eventId];
        uint256 ticketsToRefund = _event.buyers[msg.sender];
        uint256 amountToRefund = ticketsToRefund * PRICE_TICKET;

        _event.buyers[msg.sender] = 0;
        _event.sales -= ticketsToRefund;
        msg.sender.transfer(amountToRefund);

        emit LogGetRefund(msg.sender, eventId, ticketsToRefund);
        return true;
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint256 eventId)
        public
        view
        verifyCaller(eventId)
        returns (uint256 numOfTickets)
    {
        numOfTickets = events[eventId].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint256 eventId)
        public
        onlyOwner()
        eventIsOpen(eventId)
        returns (bool)
    {
        Event storage _event = events[eventId];
        uint256 eventBalance = _event.sales * PRICE_TICKET;

        _event.isOpen = false;
        msg.sender.transfer(eventBalance);

        emit LogEndSale(msg.sender, eventBalance, eventId);
        return true;
    }
}
