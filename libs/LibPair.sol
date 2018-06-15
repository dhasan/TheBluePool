
pragma solidity ^0.4.23;

library LibPair {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;
    using LibToken for LibToken.Token;
    bytes32 constant public VERSION = "LibPair 0.0.1";

    struct Entry{
        uint id;
        address addr;
        uint amount;
        bool initial;
    }

    struct Pair {
        uint id;
        bytes8 name;
        uint mainid;
        uint baseid;
        uint bestask;
        uint bestbid;

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

    function limitSell_token_x(Pair storage self, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint price, uint prevprice, uint amount, bool ini) internal {
        // Entry memory order;
        uint total;
        uint fees;


        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);
        require(price>self.bestbid || self.bestbid==0,"Invalid ask price");
        
        if (ini==false){
            self.askdom[price][self.ordercnt].addr = msg.sender;    
        }else{
            self.askdom[price][self.ordercnt].addr = address(this);
            maintoken.coininvestment = maintoken.coininvestment.add(amount);
        }
        self.askdom[price][self.ordercnt].id = ordercnt;
        self.askdom[price][self.ordercnt].initial = ini;
        self.askdom[price][self.ordercnt].amount = amount;
        //pair.askdom[price][ordercnt] = order;

        if (self.askpricelist.nodeExists(price)==true){
            self.askqueuelist[price].push(self.ordercnt,false);
        }else{
            require(price>prevprice,"Wrong price 1");
            total = self.askpricelist.step(prevprice,true);
            require(price<total,"Wrong price 2");//total=next;
            self.askpricelist.insert(prevprice,price,true);
            self.askqueuelist[price].push(self.ordercnt,false);
        }

        if (ini==true){
            fees = amount.mul(self.makerfeeratio);
            fees = fees.shiftRight(80);
            maintoken.cointotalfees = maintoken.cointotalfees.add(fees);
        }else{
            fees = 0;
        }
        total = fees.add(amount);
        if (ini==false)
            maintoken.tokencontract.transfer_origin(address(this), total);

        if (price<self.bestask || self.bestask==0){
            self.bestask = price;
            emit Quotes(self.id, self.bestask, self.bestbid);
        }

        emit PlaceOrder(self.id, msg.sender, price, self.ordercnt );
        self.ordercnt++;
    }

    function marketBuyFull_token_eth(Pair storage self, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint price, uint slippage, bool ini) internal payable {
        uint total;
        uint value = msg.value;
        require( self.bestask!=0);
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);

        if (ini==true)
            require(msg.sender==owner);
        
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
        if (ini==false){
            total = value.mul(self.takerfeeratio);
            total = total.shiftRight(80);
            value = value.sub(total);
            basetoken.cointotalfees.add(total);
        }

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

                        if (self.askdom[p][n].initial==false)
                            require(self.askdom[p][n].addr.send(total));
                        else{
                            basetoken.coininvestment = basetoken.coininvestment.add(total);
                            maintoken.coininvestment = maintoken.coininvestment.sub(self.askdom[p][n].amount);
                        }
                        if (ini==false)
                            require(maintoken.tokencontract.transfer(msg.sender, self.askdom[p][n].amount));
                        else{
                            maintoken.coininvestment = maintoken.coininvestment.add(self.askdom[p][n].amount);
                            basetoken.coininvestment = basetoken.coininvestment.sub(total);
                        }

                        emit TradeFill(self.id, self.askdom[p][n].addr, self.askdom[p][n].id, -1*int(self.askdom[p][n].amount));

                        // ethacc = ethacc.add(total);

                        vols = vols.add(self.askdom[p][n].amount);
                        self.askqueuelist[p].remove(n);
                        value = value.sub(total);
                    }else{
                        total = p.mul(amount.sub(vols));
                        total = total.shiftRight(80);
                        if (self.askdom[p][n].initial==false)
                            require(self.askdom[p][n].addr.send(total));
                        else{
                            basetoken.coininvestment = basetoken.coininvestment.add(total);
                            maintoken.coininvestment = maintoken.coininvestment.sub(amount.sub(vols));
                        }
                        if (ini==false)
                            require(maintoken.tokencontract.transfer(msg.sender, amount.sub(vols)));
                        else{
                            maintoken.coininvestment = maintoken.coininvestment.add(amount.sub(vols));
                            basetoken.coininvestment = basetoken.coininvestment.sub(total);
                        }
                        emit TradeFill(pairid, self.askdom[p][n].addr, self.askdom[p][n].id, -1*int(self.askdom[p][n].amount));
                       // ethacc = ethacc.add(total);

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
            emit Quotes(pairid, self.bestask, self.bestbid);
        }
        emit Trade(pairid, msg.sender, p, int(amount));
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
        return [self.]
    }
}