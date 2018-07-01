
pragma solidity ^0.4.23;
import "./SafeMath.sol";
import "./LibCLLu.sol";
import "./LibToken.sol";
import "./LibPair.sol";

library LibPairBid {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;
    using LibToken for LibToken.Token;
    bytes32 constant public VERSION = "LibPairBid 0.0.1";


     //bid
    function limitBuy_token_eth(LibPair.Pair storage self, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint price, uint prevprice) public returns (bool success) {
         // Entry memory order;
        uint total;
        uint fees;
        uint value = msg.value;

        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }

        require(total==0);
        require(price<self.bestask || self.bestask==0,"Invalid bid price");

        uint ordercnt = uint256(keccak256(block.timestamp, msg.sender, price, msg.value));
        require(self.bidqueuelist[price].nodeExists(ordercnt)==false);
        if (msg.sender!=self.owner){
            fees = value.mul(self.makerfeeratio);
            fees = fees.shiftRight(80);
            basetoken.cointotalfees = basetoken.cointotalfees.add(fees);
        }else
            fees = 0;
        value = value.sub(fees);

        self.biddom[price][ordercnt].addr = msg.sender;   
        total = value.shiftLeft(80);
        total = value.div(price);
        self.biddom[price][ordercnt].amount = total;

        if (self.bidpricelist.nodeExists(price)==false){
            require(price<prevprice || prevprice==0,"Wrong price 1");
            total = self.bidpricelist.step(prevprice,false);
            require(price>total || total==0,"Wrong price 2");//total=next;
            self.bidpricelist.insert(prevprice,price,false);
        }
        
        self.bidqueuelist[price].push(ordercnt,false);
        if (price>self.bestbid|| self.bestbid==0){
            self.bestbid = price;
            emit Quotes(self.id, self.bestask, self.bestbid);
        }

        emit PlaceOrder(self.id, msg.sender, price, ordercnt );

        success = true;

    }

    //bid
    function get_bid_order_price(LibPair.Pair storage self, uint orderid) public view returns(uint) {
        uint p=0;
        uint n=0;

        do {
            p= self.bidpricelist.step(p,false);
            n=0;
            do {
                n = self.bidqueuelist[p].step(n,true);
                if (n==orderid)
                    return p;
            }while((n!=orderid) && (n!=0));
        }while((p!=0) && (n!=orderid));

        return 0;
    }

     //bid
    function get_bid_order_details(LibPair.Pair storage self, uint orderid, uint price) public view returns(address, uint) { //address and amount
        return (self.biddom[price][orderid].addr, self.biddom[price][orderid].amount);
    }

    //bid
    function delete_bid_order(LibPair.Pair storage self, LibToken.Token storage basetoken, uint orderid, uint price) public returns (bool success){
        uint value;
        uint fees;
        require(self.bidpricelist.nodeExists(price));
        require(self.bidqueuelist[price].nodeExists(orderid));
        require(msg.sender == self.biddom[price][orderid].addr);
        value = self.biddom[price][orderid].amount.mul(price);
        value = value.shiftRight(80);
        if (msg.sender!=self.owner){
            fees = value.mul(self.takerfeeratio);
            fees = fees.shiftRight(80);
        }else
            fees=0;
        value = value.sub(fees);

        basetoken.cointotalfees = basetoken.cointotalfees.add(fees);
        if (basetoken.id==0)
            require(msg.sender.send(value));
        else
            basetoken.transfer_from(address(this), msg.sender, value);

        self.bidqueuelist[price].remove(orderid);
        if (self.bidqueuelist[price].sizeOf()==0){
            if (self.bestbid==price){
                self.bestbid = self.askpricelist.step(price,false);
                emit Quotes(self.id, self.bestask, self.bestbid);
            }
            self.bidpricelist.remove(price);
        }

        success = true;

    }

    event Quotes(uint pairid, uint ask, uint bid);    
    event TradeFill(uint indexed pairid, address indexed addr, uint id, int amount);
    event Trade(uint pairid, address addr, uint price, int amount);
    event PlaceOrder(uint indexed pairid, address indexed addr, uint indexed price, uint id);


}