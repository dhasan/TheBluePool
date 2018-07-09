
pragma solidity ^0.4.23;
import "./SafeMath.sol";
import "./LibCLLu.sol";
import "./LibToken.sol";
import "./LibPair.sol";

library LibPairAsk {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;
    using LibToken for LibToken.Token;
    bytes32 constant public VERSION = "LibPairAsk 0.0.1";

    //ask
    function get_ask_order_price(LibPair.Pair storage self, uint orderid) public view returns(uint) {
        uint p=0;
        uint n=0;

        do {
            p= self.askpricelist.step(p,true);
            n = 0;
            do {
                n = self.askqueuelist[p].step(n,true);
                if (n==orderid)
                    return p;
            }while((n!=orderid) && (n!=0));
        }while((p!=0) && (n!=orderid));

        return 0;
    }

     //ask
    function modify_ask_order_price(LibPair.Pair storage self, LibToken.Token storage maintoken, uint orderid, uint price, uint newprice, uint newprevprice) public returns (bool success) {
        LibPair.Entry memory tempentry;
	    uint total;

        require(newprice>self.bestbid || self.bestbid==0);
        require(self.askpricelist.nodeExists(price));
        require(self.askqueuelist[price].nodeExists(orderid));
        require(self.msgSender == self.askdom[price][orderid].addr);
        tempentry.addr = self.askdom[price][orderid].addr;
        tempentry.amount = self.askdom[price][orderid].amount;

        self.askqueuelist[price].remove(orderid);
        if (self.askqueuelist[price].sizeOf()==0){
            if (self.bestask==price){
                self.bestask = self.askpricelist.step(price,true);
                emit Quotes(self.id, self.bestask, self.bestbid);
            }
            self.askpricelist.remove(price);
        }

        if (self.askpricelist.nodeExists(newprice)==false){
            require(newprice>newprevprice,"Wrong newprice 1");
            total = self.askpricelist.step(newprevprice,true);
            require(newprice<total || total==0,"Wrong newprice 2");//total=next;
            self.askpricelist.insert(newprevprice,newprice,true);
        }

        self.askqueuelist[newprice].push(orderid,false);

        self.askdom[newprice][orderid].addr = tempentry.addr;
        self.askdom[newprice][orderid].amount = tempentry.amount;

        if (newprice<self.bestask){
            emit Quotes(self.id, self.bestask, self.bestbid);   
        }

        success = true;
    }
    //ask
    function get_ask_order_details(LibPair.Pair storage self, uint orderid, uint price) public view returns(address, uint) { //address and amount
        return (self.askdom[price][orderid].addr, self.askdom[price][orderid].amount);
    }
   
    //ask
    function delete_ask_order(LibPair.Pair storage self, LibToken.Token storage maintoken, uint orderid, uint price) public returns (bool success){
        uint total;
        require(self.askpricelist.nodeExists(price));
        require(self.askqueuelist[price].nodeExists(orderid));
        require(self.msgSender == self.askdom[price][orderid].addr);
        if (self.owner!=self.msgSender){
            total = self.askdom[price][orderid].amount.mul(self.takerfeeratio);
            total = total.shiftRight(80);
            maintoken.cointotalfees = maintoken.cointotalfees.add(total);
        }else
            total=0;
        total = self.askdom[price][orderid].amount.sub(total);
        if (maintoken.id==0)
            require(self.msgSender.send(total));
        else
            maintoken.transfer_from(address(this), self.msgSender, total);
        self.askqueuelist[price].remove(orderid);
        if (self.askqueuelist[price].sizeOf()==0){
            if (self.bestask==price){
                self.bestask = self.askpricelist.step(price,true);
                emit Quotes(self.id, self.bestask, self.bestbid);
            }
            self.askpricelist.remove(price);            
        }

        success=true;
    }
    
    //ask
    function limitSell(LibPair.Pair storage self, LibToken.Token storage maintoken, uint orderid, uint price, uint prevprice, uint amount) public returns (bool success){
        uint total;
        uint fees;

        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);
        require(price>self.bestbid || self.bestbid==0,"Invalid ask price");
        
       // uint ordercnt = uint256(keccak256(block.timestamp, self.msgSender, price, amount));

        require(self.askqueuelist[price].nodeExists(orderid)==false);
        self.askdom[price][orderid].addr = self.msgSender;    
        
        if (self.askpricelist.nodeExists(price)==true){
            self.askqueuelist[price].push(orderid,false);
        }else{
            require(price>prevprice || prevprice==0,"Wrong price 1");
            total = self.askpricelist.step(prevprice,true);
            require(price<total || total==0,"Wrong price 2");//total=next;
            self.askpricelist.insert(prevprice,price,true);
            self.askqueuelist[price].push(orderid,false);
        }
        if (self.msgSender!=self.owner){
            fees = amount.mul(self.makerfeeratio);
            fees = fees.shiftRight(80);
            maintoken.cointotalfees = maintoken.cointotalfees.add(fees);
        }else
            fees=0;
        self.askdom[price][orderid].amount = amount.sub(fees);
       // total = amount.sub(fees);
        maintoken.transfer_from(self.msgSender, address(this), amount);

        if (price<self.bestask || self.bestask==0){
            self.bestask = price;
            emit Quotes(self.id, self.bestask, self.bestbid);
        }

        emit PlaceOrder(self.id, self.msgSender, price, orderid );
    	success = true;
    }

    //ask
    
    function marketBuyFull(LibPair.Pair storage self, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint slippage, uint valuep) internal {
        uint total;
        if (basetoken.id==0)
       		require(valuep==msg.value);
       	else
       		require(basetoken.transfer_from(self.msgSender, address(this), valuep));
        uint value = valuep;
        require( self.bestask!=0);
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);
        
        uint p = self.bestask;
        uint n;
        uint vols = 0;
        uint amount;
        if (self.msgSender!=self.owner){
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
                        if (basetoken.id==0)
                        	require(self.askdom[p][n].addr.send(total));
                        else
                        	require(basetoken.transfer_from(address(this), self.askdom[p][n].addr, total));
                        require(maintoken.transfer_from(address(this), self.msgSender, self.askdom[p][n].amount));
                        
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
                        if (basetoken.id==0)
                        	require(self.askdom[p][n].addr.send(total));
                        else
                        	require(basetoken.transfer_from(address(this),self.askdom[p][n].addr, total));
                        require(maintoken.transfer_from(address(this), self.msgSender, amount.sub(vols)));
                       
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
                require((p.sub(self.bestask)) < slippage);
            }
        }while(vols<amount);
        if (slippage!=0)
            require((p.sub(self.bestask)) < slippage);

        if (p!=self.bestask){
            self.bestask=p;
            emit Quotes(self.id, self.bestask, self.bestbid);
        }
        emit Trade(self.id, self.msgSender, p, int(amount));

       // success = true;
    }

    event Quotes(uint pairid, uint ask, uint bid);    
    event TradeFill(uint indexed pairid, address indexed addr, uint id, int amount);
    event Trade(uint pairid, address addr, uint price, int amount);
    event PlaceOrder(uint indexed pairid, address indexed addr, uint indexed price, uint id);
}
