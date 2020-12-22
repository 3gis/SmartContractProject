pragma solidity >=0.7.0 <0.8.0;

// storage calldata gali netiks bbz ka cia uzdejau

contract CallAuction{
    mapping(address => address[]) contracts;
    mapping(address => Auction) userContracts;
    address[] AddressList;
    function CallAuctionf(string memory name, uint value, string memory description, uint _bidIncrement, uint _biddingTime) external {
        Auction d = new Auction();
        contracts[msg.sender].push(address(d));
        userContracts[address(d)] = d;
        AddressList.push(address(d));
        d.addItemToAuction(name, value, description, _bidIncrement, _biddingTime);
    }
    function GetYourAuctionAddress() external view returns(address[] memory){
        return contracts[msg.sender];
    }
    function CallgetItemCurrentTopBid(address a) view external returns(uint){
        return userContracts[a].getItemCurrentTopBid();
    }
    function CallgetItemName(address a) view external returns(string memory){
        return userContracts[a].getItemName();
    }
    function CallgetItemDescription(address a) view external returns(string memory){
        return userContracts[a].getItemDescription();
    }
    function CallgetItemWinner(address a) view external returns(address){
        return userContracts[a].getItemWinner();
    }
    function CallgetTimeLeft(address a) view external returns(uint){
        return userContracts[a].getTimeLeft();
    }
    function CallBid(address a) payable external{
        userContracts[a].Bid(msg.value);
    }
    function CallCloseAuction(address a) external{
        userContracts[a].CloseAuction();
    }
    function CallWithdraw(address a) external returns(uint){
        return userContracts[a].withdraw();
    }
    function CallGetInfoOnAll() external {
        for(uint i = 0; i<AddressList.length;i++)
            userContracts[AddressList[i]].getInfo();
    }
}




contract Auction{
    struct Item{
        string name;
        uint basePrice;
        string description;
    }
    
    struct ItemInAuction{
        Item item;
        uint currentPrice;
        uint minBid;
        uint bidIncrement;
        address payable Seller; // prisimink seller
        address Winner;
        uint closeAuctionTime;
    }
    mapping(address => uint) BidderList;
    Item newItem;
    ItemInAuction auctionItem;
    bool isItemInAuction;
    bool auctionComplete;
    
    address[] BidderListIndexes;
    
    event topBidIncreased(address bidder, uint bidAmount, uint nextMinBid);
    event auctionResult(address winner, uint bidAmount);
    event WithdrawAllResults(uint failedTransactions);
    event SendInfoToFront(string name, string description, address Winner, uint TimeLeft);
    event emitValue(uint value);
    function getItemCurrentTopBid() external view returns(uint){
        return auctionItem.minBid;
    }
    function getItemName() external view returns(string memory){
        return newItem.name;
    }
    function getItemDescription() external view returns(string memory){
        return newItem.description;
    }
    function getItemWinner() external view returns(address){
        return auctionItem.Winner;
    }
    function getTimeLeft() external view returns(uint){
        if(auctionComplete){
            return 996980085;
        }
        else if(block.timestamp <= auctionItem.closeAuctionTime)
            return auctionItem.closeAuctionTime - block.timestamp;
        else return 0;
    }
    function getInfo() external {
        if(!auctionComplete){
            emit SendInfoToFront(newItem.name, newItem.description, auctionItem.Winner, auctionItem.closeAuctionTime - block.timestamp);
        }    
    }
    
    function addItemToAuction(string memory name, uint value, string memory description, uint _bidIncrement, uint _biddingTime) external {
        require(!isItemInAuction, "Can't add another item to an existing auction!");
        newItem.name = name;
        newItem.basePrice = value;
        newItem.description = description;
        if(AddToAuction(newItem, _bidIncrement, _biddingTime)){
            isItemInAuction = true;
        }
    }
    /*
    function addItemToAuction(string calldata name, uint value, uint _bidIncrement, uint _biddingTime, address msgSender) external {
        require(!isItemInAuction, "Can't add another item to an existing auction!");
        newItem.name = name;
        newItem.basePrice = value;
        if(AddToAuction(newItem, _bidIncrement, _biddingTime)){
            isItemInAuction = true;
        }
    }
    */
    function AddToAuction(Item memory _item, uint _bidIncrement, uint _biddingTime) private returns(bool){
        ItemInAuction memory newAuctionItem;
        newAuctionItem.item = _item;
        newAuctionItem.currentPrice = _item.basePrice;
        newAuctionItem.minBid = _item.basePrice + _bidIncrement;
        newAuctionItem.bidIncrement = _bidIncrement;
        newAuctionItem.Seller = tx.origin;
        newAuctionItem.closeAuctionTime = block.timestamp + _biddingTime;
        auctionItem = newAuctionItem;
        return true;
    }
    
    /*function BidOnItem(uint value) external{
        if(value < auctionItem.minBid)
            revert();
        else{
            auctionItem.currentPrice = value;
            auctionItem.minBid = value+auctionItem.bidIncrement;
            auctionItem.Winner = msg.sender;
        }
    }*/
    function Bid(uint value) payable external{
        require(block.timestamp <= auctionItem.closeAuctionTime, "Auction already closed.");
        require(BidderList[tx.origin]+value > auctionItem.minBid, "Can't bid less than minimal bid!"); //pataisyt
        require(tx.origin != auctionItem.Seller, "Seller can't bid on their own items!");
        require(tx.origin != msg.sender, "You can't access this function without 3rd party!");
        BidderList[tx.origin] = BidderList[tx.origin]+value;
        //BidderListIndexes.push(tx.origin);
        auctionItem.Winner = tx.origin;
        auctionItem.minBid = value + auctionItem.bidIncrement;
        emit topBidIncreased(tx.origin, value + BidderList[tx.origin], auctionItem.minBid);
    }
    function CloseAuction() external returns(uint){
        require(block.timestamp >= auctionItem.closeAuctionTime, "Auction is still in progress!"); // auction did not yet end
        require(!auctionComplete, "Auction already closed!"); // this function has already been called
        auctionComplete = true;
        emit auctionResult(auctionItem.Winner, BidderList[auctionItem.Winner]);
        if(auctionItem.Winner!=address(0))
            auctionItem.Seller.transfer(BidderList[auctionItem.Winner]);
        return 0;
        //withdrawAll();
    }
    function withdraw() external returns (uint) {
        uint bidAmount = BidderList[tx.origin];
        if (bidAmount > 0) {
            BidderList[tx.origin] = 0;

            if (!tx.origin.send(bidAmount)) {
                BidderList[tx.origin] = bidAmount;
                return 0;
            }
        }
        return bidAmount;
    }
    /*
    function withdrawAll() internal returns (uint){
        uint failedTransactionNumber;
        uint length = BidderListIndexes.length;
        for(uint i = 0; i<length;i++){
            uint bidAmount = BidderList[msg.sender];
            if (bidAmount > 0) {
                BidderList[msg.sender] = 0;
                if (!msg.sender.send(bidAmount)) {
                    BidderList[msg.sender] = bidAmount;
                    failedTransactionNumber++;
                }
            }
        }
    emit WithdrawAllResults(failedTransactionNumber);
    return failedTransactionNumber;
    }*/
}