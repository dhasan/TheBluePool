
pragma solidity ^0.4.23;
import "./SafeMath.sol";
import "./LibCLLu.sol";
import "./LibToken.sol";
import "./LibPairAsk.sol";
import "./LibPairBid.sol";

library LibPair {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;
    using LibToken for LibToken.Token;
    using LibPairAsk for Pair;
    using LibPairBid for Pair;
    bytes32 constant public VERSION = "LibPair 0.0.1";

    struct Entry{
       //uint id;
        address addr;
        uint amount; //tokens count
        uint value; //total eth
       
    }

    struct Pair {
        uint id;
        bytes8 name;
        uint mainid;
        uint baseid;
        uint bestask;
        uint bestbid;

        address owner;

        LibCLLu.CLL askpricelist;
        mapping (uint => LibCLLu.CLL) askqueuelist;
        mapping (uint => mapping (uint => Entry)) askdom;

        LibCLLu.CLL bidpricelist;
        mapping (uint => LibCLLu.CLL) bidqueuelist;
        mapping (uint => mapping (uint => Entry)) biddom;

        uint ordercnt;
        uint takerfeeratio;
        uint makerfeeratio;
    }
    
    function get_ask_order_price(Pair storage self, uint orderid) internal view returns(uint) {
        return self.get_ask_order_price(orderid);
    }

    function get_bid_order_price(Pair storage self, uint orderid) internal view returns(uint) {
        return self.get_bid_order_price(orderid);
    }

    function modify_ask_order_price(Pair storage self, LibToken.Token storage maintoken, uint orderid, uint price, uint newprice, uint newprevprice) internal returns(bool success){
        success = self.modify_ask_order_price(maintoken, orderid, price, newprice, newprevprice);
    }
   

    function getPairTokenIds(Pair storage self) internal view returns(uint[2]){
        return [self.mainid, self.baseid];
    }

    function getPairName(Pair storage self) internal view returns(bytes8){
        return self.name;
    }

    function getPrices(Pair storage self) internal view returns(uint[2]){
        return [self.bestask, self.bestbid];
    }

    function getPrevAsk(Pair storage self, uint price) internal view returns (uint){  
        return self.askpricelist.seek(0,price, false);
    }

    function getPrevBid(Pair storage self, uint price) internal view returns (uint){  
        return self.bidpricelist.seek(0,price, true);
    }

    function askPriceExists(Pair storage self, uint price) internal view returns(bool){
        return self.askpricelist.nodeExists(price);
    }

    function bidPriceExists(Pair storage self, uint price) internal view returns(bool){
        return self.bidpricelist.nodeExists(price);
    }

    function getAskDOMPrice(Pair storage self, uint prevprice) internal view returns(uint){
        return self.askpricelist.step(prevprice,true);   
    }

    function getBidDOMPrice(Pair storage self, uint prevprice) internal view returns(uint){
        return self.bidpricelist.step(prevprice,false);   
    }

    function getAskDOMAmounts(Pair storage self, uint price) internal view returns(uint){
        uint acc=0;
        uint n=0;
        do{
            n = self.askqueuelist[price].step(n,true);
            acc = acc.add(self.askdom[price][n].amount);
        }while(n!=0);

        return acc;
    }

    function getBidDOMAmounts(Pair storage self, uint price) internal view returns(uint){
        uint acc=0;
        uint n=0;
        do{
            n = self.bidqueuelist[price].step(n,true);
            acc = acc.add(self.askdom[price][n].amount);
        }while(n!=0);

        return acc;
    }

    function createPair(Pair storage self, bytes8 _name, uint m, uint b, uint makerfee, uint takerfee) internal returns(bool success){
        self.name = _name;
        self.mainid = m;
        self.baseid = b;
        self.bestask = 0;
        self.bestbid = 0;
        self.makerfeeratio = makerfee;
        self.takerfeeratio = takerfee;
        success = true;
    }

    function limitSell_token_x(Pair storage self, LibToken.Token storage maintoken, uint price, uint prevprice, uint amount) internal returns(bool success){
        success = self.limitSell_token_x(maintoken, price, prevprice, amount);
    }

 /*   function get_ask_order_details(Pair storage self, uint orderid, uint price) internal view returns(address, uint) { //address and amount
        return self.get_ask_order_details()
    }*/

    function marketBuyFull_token_eth(Pair storage self, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint price, uint slippage) internal returns(bool success) {
        success = self.marketBuyFull_token_eth(maintoken, basetoken, price, slippage);
    }

    function getFeesRatios(Pair storage self) internal view returns(uint[2]){
        return [self.makerfeeratio, self.takerfeeratio];
    }

    event Quotes(uint pairid, uint ask, uint bid);    
    event TradeFill(uint indexed pairid, address indexed addr, uint id, int amount);
    event Trade(uint pairid, address addr, uint price, int amount);
    event PlaceOrder(uint indexed pairid, address indexed addr, uint indexed price, uint id);
}
