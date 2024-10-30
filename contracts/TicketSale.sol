// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract TicketSale {
    address public manager;
    uint public ticketPrice;
    uint public numTickets;
    mapping(uint => address) public ticketOwners;
    mapping(address => uint) public ticketsOwnedBy;
    mapping(uint => uint) public resalePrices;
    mapping(uint => address) public swapOffers;

    constructor(uint _numTickets, uint _price) {
        manager = msg.sender;
        numTickets = _numTickets;
        ticketPrice = _price;
    }

    modifier onlyManager() {
        require(
            msg.sender == manager,
            "Only the manager can perform this action."
        );
        _;
    }

    function buyTicket(uint ticketId) public payable {
        require(ticketId > 0 && ticketId <= numTickets, "Invalid ticket ID.");
        require(msg.value == ticketPrice, "Incorrect amount sent.");
        require(ticketOwners[ticketId] == address(0), "Ticket already sold.");
        require(ticketsOwnedBy[msg.sender] == 0, "You already own a ticket.");

        ticketOwners[ticketId] = msg.sender;
        ticketsOwnedBy[msg.sender] = ticketId;
    }

    function getTicketOf(address person) public view returns (uint) {
        return ticketsOwnedBy[person];
    }

    function offerSwap(uint ticketId) public {
        require(
            ticketOwners[ticketId] == msg.sender,
            "You don't own this ticket."
        );
        swapOffers[ticketId] = msg.sender;
    }

    function acceptSwap(uint ticketId) public {
        address offerOwner = swapOffers[ticketId];
        require(offerOwner != address(0), "No swap offer for this ticket.");
        require(
            ticketOwners[ticketId] == offerOwner,
            "Offer owner does not own the ticket."
        );
        require(
            ticketsOwnedBy[msg.sender] > 0,
            "You don't own any ticket to swap."
        );

        uint otherTicketId = ticketsOwnedBy[msg.sender];

        // Debugging logs for state before swap (for Remix or compatible IDEs)
        emit SwapDebug(offerOwner, msg.sender, ticketId, otherTicketId);

        // Swap ticket ownership
        ticketOwners[ticketId] = msg.sender;
        ticketOwners[otherTicketId] = offerOwner;
        ticketsOwnedBy[msg.sender] = ticketId;
        ticketsOwnedBy[offerOwner] = otherTicketId;

        // Clear the swap offer
        delete swapOffers[ticketId];

        // Debugging logs for state after swap
        emit SwapDebug(
            ticketOwners[ticketId],
            ticketOwners[otherTicketId],
            ticketsOwnedBy[msg.sender],
            ticketsOwnedBy[offerOwner]
        );
    }

    // Event for debugging swap details
    event SwapDebug(
        address offerOwner,
        address newOwner,
        uint ticketId,
        uint otherTicketId
    );

    function resaleTicket(uint price) public {
        uint ticketId = ticketsOwnedBy[msg.sender];
        require(ticketId > 0, "You don't own a ticket.");
        resalePrices[ticketId] = price;
    }

    function acceptResale(uint ticketId) public payable {
        uint resalePrice = resalePrices[ticketId];
        require(resalePrice > 0, "Ticket not for resale.");
        require(msg.value == resalePrice, "Incorrect amount sent.");
        require(ticketsOwnedBy[msg.sender] == 0, "You already own a ticket.");

        address previousOwner = ticketOwners[ticketId];
        uint managerFee = (resalePrice * 10) / 100;
        uint ownerAmount = resalePrice - managerFee;

        payable(previousOwner).transfer(ownerAmount);
        payable(manager).transfer(managerFee);

        ticketOwners[ticketId] = msg.sender;
        ticketsOwnedBy[msg.sender] = ticketId;
        delete resalePrices[ticketId];
        delete ticketsOwnedBy[previousOwner];
    }

    function checkResale() public view returns (uint[] memory) {
        uint resaleCount = 0;
        for (uint i = 1; i <= numTickets; i++) {
            if (resalePrices[i] > 0) {
                resaleCount++;
            }
        }

        uint[] memory resaleTickets = new uint[](resaleCount);
        uint index = 0;
        for (uint i = 1; i <= numTickets; i++) {
            if (resalePrices[i] > 0) {
                resaleTickets[index] = i;
                index++;
            }
        }

        return resaleTickets;
    }
}