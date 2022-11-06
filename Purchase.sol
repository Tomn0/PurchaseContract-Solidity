// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;
// import "hardhat/console.sol";
contract Purchase {
    uint public price;
    uint public qty;
    address payable public buyer;
    address payable public seller;
    uint public chainStartTime;
    uint public itemReceivedTime;

    enum State {Init, Locked, Inactive, Refund}
    State public state;

    constructor() payable{
        seller = payable(msg.sender);
        price = msg.value / 2;
        state = State.Init;

        chainStartTime = block.timestamp;
    }

    ///This function can't be called at this time
    error InvalidState();

    modifier inState(State state_){
        if(state != state_){
            revert InvalidState();
        }
        _;
    }

    ///You are not the item seller!
    error notSeller();

    modifier isSeller(){
        if(msg.sender != seller){
            revert notSeller();
        }
        _;
    }

    ///You are not the item buyer!
    error notBuyer();

      modifier isBuyer(){
        if(msg.sender != buyer){
            revert notBuyer();
        }
        _;
    }

    function buyProduct() external inState(State.Init) payable{
        // this function is called in the state 'Init' abd the caller becomes the buyer
        require(msg.sender != seller, "You are not allowed to buy your own item");
        require(msg.value == (2*price), "You need to send value of 2x price");
        buyer = payable(msg.sender);
        itemReceivedTime = block.timestamp + 10000;
        // console.log("Timestamp: %s", block.timestamp);
        state = State.Locked;
    }

    function confirmReceivedItem() external isBuyer() inState(State.Locked) {
        // this function is called by the buyer agter receiving the item and accepting it's state
        state = State.Inactive;
        buyer.transfer(price);
        seller.transfer(3*price);

    }

    function requestRefund() external isBuyer() inState(State.Locked) {
        // this function is called in the state 'Locked' when the buyer doesn't like the item and wants to request a refund
        // console.log("Timestamp: %s", block.timestamp);
        require((block.timestamp - itemReceivedTime) < 10000, "You are not allowed to return the product anymore");
        state = State.Refund;

    }

    function confirmPurchaseCancellation() external isSeller() inState(State.Refund) {
        // this function is called by the seller when the contract is in the state 'Refund' and the buyer has returned the item
        state = State.Inactive;
        buyer.transfer(2*price);
        seller.transfer(2*price);

    }

    function abort() external isSeller() inState(State.Init) {
        // this function is called when the contract is in the state 'Init' and the seller wishes to cancel the offer
        state = State.Inactive;
        seller.transfer(2*price);

    }

}

// TODO:
// check if buyer or if seller
// advertise what item is for sale
// the buyer can just use the item for some time and return in afterwards and get the money back -> add some timeout when the refund state becomes unavailable

