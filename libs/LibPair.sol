
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
      //  uint value; //total eth
       
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
    
    function get_ask_order_price(Pair storage self, uint orderid) public view returns(uint) {
        return self.get_ask_order_price(orderid);
    }

    function get_bid_order_price(Pair storage self, uint orderid) public view returns(uint) {
        return self.get_bid_order_price(orderid);
    }

    function modify_ask_order_price(Pair storage self, LibToken.Token storage maintoken, uint orderid, uint price, uint newprice, uint newprevprice) public returns(bool success){
        success = self.modify_ask_order_price(maintoken, orderid, price, newprice, newprevprice);
    }
   

    function getPairTokenIds(Pair storage self) public view returns(uint[2]){
        return [self.mainid, self.baseid];
    }

    function getPairName(Pair storage self) public view returns(bytes8){
        return self.name;
    }

    function getPrices(Pair storage self) public view returns(uint[2]){
        return [self.bestask, self.bestbid];
    }

    function getPrevAsk(Pair storage self, uint price) public view returns (uint){  
        return self.askpricelist.seek(0,price, false);
    }

    function getPrevBid(Pair storage self, uint price) public view returns (uint){  
        return self.bidpricelist.seek(0,price, true);
    }

    function askPriceExists(Pair storage self, uint price) public view returns(bool){
        return self.askpricelist.nodeExists(price);
    }

    function bidPriceExists(Pair storage self, uint price) public view returns(bool){
        return self.bidpricelist.nodeExists(price);
    }

    function getAskDOMPrice(Pair storage self, uint prevprice) public view returns(uint){
        return self.askpricelist.step(prevprice,true);   
    }

    function getBidDOMPrice(Pair storage self, uint prevprice) public view returns(uint){
        return self.bidpricelist.step(prevprice,false);   
    }

    function getAskDOMAmounts(Pair storage self, uint price) public view returns(uint){
        uint acc=0;
        uint n=0;
        do{
            n = self.askqueuelist[price].step(n,true);
            acc = acc.add(self.askdom[price][n].amount);
        }while(n!=0);

        return acc;
    }

    function getBidDOMAmounts(Pair storage self, uint price) public view returns(uint){
        uint acc=0;
        uint n=0;
        do{
            n = self.bidqueuelist[price].step(n,true);
            acc = acc.add(self.askdom[price][n].amount);
        }while(n!=0);

        return acc;
    }

    function createPair(Pair storage self, bytes8 _name, uint m, uint b, uint makerfee, uint takerfee) public returns(bool success){
        self.name = _name;
        self.mainid = m;
        self.baseid = b;
        self.bestask = 0;
        self.bestbid = 0;
        self.makerfeeratio = makerfee;
        self.takerfeeratio = takerfee;
        success = true;
    }

    function limitSell_token_x(Pair storage self, LibToken.Token storage maintoken, uint price, uint prevprice, uint amount) public returns(bool success){
        success = self.limitSell_token_x(maintoken, price, prevprice, amount);
    }

 /*   function get_ask_order_details(Pair storage self, uint orderid, uint price) public view returns(address, uint) { //address and amount
        return self.get_ask_order_details()
    }*/

    function marketBuyFull_token_eth(Pair storage self, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint price, uint slippage) internal returns(bool success) {
       // success = self.marketBuyFull_token_eth(maintoken, basetoken, price, slippage);
        uint total;
        uint value = msg.value;
        require( self.bestask!=0);
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);
        
        if ((price!=self.bestask) && (slippage!=0) && (price!=0)){
            if (price>self.bestask){
                require((price.sub(self.bestask)) < slippage);
            }else{
                require((self.bestask.sub(price)) < slippage);
            }
        }
        uint p = self.bestask;
        uint n;
        uint vols = 0;
        uint amount;
        if (msg.sender!=self.owner){
            total = value.mul(self.takerfeeratio);
            total = total.shiftRight(80);
            basetoken.cointotalfees.add(total);
        }else
            total=0;

        value = value.sub(total);

        do {
            n=0;
            do {
                n = self.askqueuelist[p].step(n, true);
                amount = value.shiftLeft(80);
                amount = value.div(p);
                if (n!=0){
                    
                    if (self.askdom[p][n].amount<=amount.sub(vols)){
                        total = p.mul(self.askdom[p][n].amount);
                        total = total.shiftRight(80);

                        require(self.askdom[p][n].addr.send(total));
                        require(maintoken.transfer_from(address(this), msg.sender, self.askdom[p][n].amount));
                        
                        emit TradeFill(self.id, self.askdom[p][n].addr, n, -1*int(self.askdom[p][n].amount));

                        vols = vols.add(self.askdom[p][n].amount);
                        self.askqueuelist[p].remove(n);
                        if (self.askqueuelist[p].sizeOf()==0){
                            self.askpricelist.remove(p);
                        }
                        value = value.sub(total);
                    }else{
                        total = p.mul(amount.sub(vols));
                        total = total.shiftRight(80);

                        require(self.askdom[p][n].addr.send(total));
                        require(maintoken.transfer_from(address(this), msg.sender, amount.sub(vols)));
                       
                        emit TradeFill(self.id, self.askdom[p][n].addr, n, -1*int(amount.sub(vols)));

                        self.askdom[p][n].amount.sub(amount.sub(vols));
                        vols = vols.add(amount.sub(vols));
                        value = value.sub(total);
                    }
                }
            } while((n!=0) && (vols<amount));
            if (n==0){
                p = self.askpricelist.step(p,true); //ask is true
                require(p!=0,"Not enought market volume");
                if ((slippage!=0) && (price!=0))
                    require((p.sub(price)) < slippage);
            }
        }while(vols<amount);
        if (slippage!=0)
            require((p.sub(price)) < slippage);

        if (p!=self.bestask){
            self.bestask=p;
            emit Quotes(self.id, self.bestask, self.bestbid);
        }
        emit Trade(self.id, msg.sender, p, int(amount));

        success = true;
    }

    function getFeesRatios(Pair storage self) public view returns(uint[2]){
        return [self.makerfeeratio, self.takerfeeratio];
    }

    event Quotes(uint pairid, uint ask, uint bid);    
    event TradeFill(uint indexed pairid, address indexed addr, uint id, int amount);
    event Trade(uint pairid, address addr, uint price, int amount);
    event PlaceOrder(uint indexed pairid, address indexed addr, uint indexed price, uint id);
}
