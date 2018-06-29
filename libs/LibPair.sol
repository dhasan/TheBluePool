
pragma solidity ^0.4.23;
import "./SafeMath.sol";
import "./LibCLLu.sol";
import "./LibToken.sol";

library LibPair {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;
    using LibToken for LibToken.Token;
    bytes32 constant public VERSION = "LibPair 0.0.1";

    struct Entry{
       //uint id;
        address addr;
        uint amount;
       
    }

    struct Pair {
        uint id;
        bytes8 name;
        uint mainid;
        uint baseid;
        uint bestask;
        uint bestbid;
        uint vol;

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

    function limitBuy_token_eth(Pair storage self, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint price, uint prevprice) internal {
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

        fees = value.mul(self.makerfeeratio);
        fees = fees.shiftRight(80);
        basetoken.cointotalfees = basetoken.cointotalfees.add(fees);
        value = value.sub(fees);

        self.biddom[price][ordercnt].addr = msg.sender;   
        total = value.shiftLeft(80);
        total = value.div(price);
        self.biddom[price][ordercnt].amount = total;

        if (self.bidpricelist.nodeExists(price)==true){
            self.bidqueuelist[price].push(ordercnt,false);
        }else{
            require(price<prevprice,"Wrong price 1");
            total = self.bidpricelist.step(prevprice,false);
            require(price>total,"Wrong price 2");//total=next;
            self.bidpricelist.insert(prevprice,price,false);
            self.bidqueuelist[price].push(ordercnt,false);
        }

        if (price>self.bestbid|| self.bestbid==0){
            self.bestbid = price;
            emit Quotes(self.id, self.bestask, self.bestbid);
        }

        emit PlaceOrder(self.id, msg.sender, price, ordercnt );

    }

    function delete_ask_order(Pair storage self, LibToken.Token storage maintoken, uint orderid, uint price) internal {
        uint total;
        require(self.askpricelist.nodeExists(price));
        require(self.askqueuelist[price].nodeExists(orderid));
        require(msg.sender == self.askdom[price][ordercnt].addr);
        total = self.askdom[price][ordercnt].amount.mul(self.takerfeeratio);
        total = total.shiftRight(80);
        maintoken.cointotalfees = maintoken.cointotalfees.add(total);
        total = self.askdom[price][ordercnt].amount.sub(total);
        if (maintoken.id==0)
            require(msg.sender.send(total));
        else
            maintoken.tokencontract.transfer_from(address(this), msg.sender, total);
        self.askqueuelist[price].remove(orderid);
        if (self.askqueuelist[price].sizeOf()==0){
            self.askpricelist.remove(price);
        }

    }

    function delete_bid_order(Pair storage self, LibToken.Token storage basetoken, uint orderid, uint price) internal {
        uint value;
        uint fees;
        require(self.bidpricelist.nodeExists(price));
        require(self.bidqueuelist[price].nodeExists(orderid));
        require(msg.sender == self.biddom[price][ordercnt].addr);
        value = self.biddom[price][ordercnt].amount.mul(price);
        value = value.shiftRight(80);
        fees = value.mul(self.takerfeeratio);
        fees = fees.shiftRight(80);
        value = value.sub(fees);

        basetoken.cointotalfees = basetoken.cointotalfees.add(fees);
        if (basetoken.id==0)
            require(msg.sender.send(value));
        else
            maintoken.tokencontract.transfer_from(address(this), msg.sender, value);

        self.bidqueuelist[price].remove(orderid);
        if (self.bidqueuelist[price].sizeOf()==0){
            self.bidpricelist.remove(price);
        }

    }

    function limitSell_token_x(Pair storage self, LibToken.Token storage maintoken, uint price, uint prevprice, uint amount) internal {
        // Entry memory order;
        uint total;
        uint fees;


        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);
        require(price>self.bestbid || self.bestbid==0,"Invalid ask price");
        
        uint ordercnt = uint256(keccak256(block.timestamp, msg.sender, price, amount));

        self.askdom[price][ordercnt].addr = msg.sender;    
        self.askdom[price][ordercnt].amount = amount;

        if (self.askpricelist.nodeExists(price)==true){
            self.askqueuelist[price].push(ordercnt,false);
        }else{
            require(price>prevprice,"Wrong price 1");
            total = self.askpricelist.step(prevprice,true);
            require(price<total,"Wrong price 2");//total=next;
            self.askpricelist.insert(prevprice,price,true);
            self.askqueuelist[price].push(ordercnt,false);
        }

        fees = amount.mul(self.makerfeeratio);
        fees = fees.shiftRight(80);
        maintoken.cointotalfees = maintoken.cointotalfees.add(fees);

        total = fees.add(amount);
        maintoken.tokencontract.transfer_from(msg.sender, address(this), total);

        if (price<self.bestask || self.bestask==0){
            self.bestask = price;
            emit Quotes(self.id, self.bestask, self.bestbid);
        }

        emit PlaceOrder(self.id, msg.sender, price, ordercnt );
        //self.ordercnt++;
    }

    function marketBuyFull_token_eth(Pair storage self, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint price, uint slippage) internal {
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
       // if (ini==false){
        total = value.mul(self.takerfeeratio);
        total = total.shiftRight(80);
        value = value.sub(total);
        basetoken.cointotalfees.add(total);
        //}

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
                        require(maintoken.tokencontract.transfer_from(address(this), msg.sender, self.askdom[p][n].amount));
                        
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
                        require(maintoken.tokencontract.transfer_from(address(this), msg.sender, amount.sub(vols)));
                       
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
        return self.askpricelist.seek(0,price, true);
    }

    function askPriceExists(Pair storage self, uint price) internal view returns(bool){
        return self.askpricelist.nodeExists(price);
    }

    function getAskDOMPrice(Pair storage self, uint prevprice) internal view returns(uint){
        return self.askpricelist.step(prevprice,true);   
    }

    function getAskDOMVolume(Pair storage self, uint price) internal view returns(uint){
        uint n = self.askqueuelist[price].step(0,true);
        if (n==0) return 0;
        uint acc = self.askdom[price][n].amount;
        while(n!=0){
            n = self.askqueuelist[price].step(n,true);
            acc = acc.add(self.askdom[price][n].amount);
        }
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

    function getFeesRatios(Pair storage self) internal view returns(uint[2]){
        return [self.makerfeeratio, self.takerfeeratio];
    }

    event Quotes(uint pairid, uint ask, uint bid);    
    event TradeFill(uint indexed pairid, address indexed addr, uint id, int amount);
    event Trade(uint pairid, address addr, uint price, int amount);
    event PlaceOrder(uint indexed pairid, address indexed addr, uint indexed price, uint id);
}