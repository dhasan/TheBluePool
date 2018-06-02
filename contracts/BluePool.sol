pragma solidity ^0.4.23;

import "../libs/LibCLLu.sol";
import "../libs/LibCLLa.sol";
import "./BlueToken.sol";
import "./Owned.sol";

contract BluePool is Owned {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;    
    using LibCLLa for LibCLLa.CLL;
    uint ordercnt;
    
    struct Entry{
        uint id;
        address addr;
        uint amount;
        bool initial;
    }

    struct Pair {
        bytes8 name;
        uint mainid;
        uint baseid;
        uint bestask;
        uint bestbid;

        LibCLLu.CLL askpricelist;
        mapping (uint => LibCLLu.CLL) askqueuelist;
        mapping (uint => mapping (uint => Entry)) askdom;
    }

    struct Token {
        uint coininvestment;
        uint cointotalfees;
       // LibCLLa.CLL coindepositlist;
       // mapping (address => uint) coindeposits;
        BlueToken tokencontract;
    }  

    Pair[] pairs;
    Token[] tokens;  

    uint takerfeeratio;
    uint makerfeeratio;
   
    constructor() Owned() public {
        ordercnt = 1;
        Token memory t;
        tokens.push(t);

    }   
    function createToken(bytes4 name, bytes32 desc, uint supply) public onlyOwner returns(uint){
        Token memory t;
        t.tokencontract = new BlueToken(tokens.length, supply, name, desc);
        return tokens.push(t) - 1;
    }  
    function createPair(bytes8 _name, uint m, uint b) public onlyOwner returns(uint){
        Pair memory p;
        require(m!=b);
        require((tokens.length) > m);
        require((tokens.length) > b);
        p.name = _name;
        p.mainid = m;
        p.baseid = b;
        p.bestask = 0;
        p.bestbid = 0;
        return pairs.push(p) - 1;
    }

    function getPrices(uint pairid) public view returns(uint[2]){
        var pair = pairs[pairid];
    	return [pair.bestask, pair.bestbid];
    }
    function getPrevAsk(uint pairid, uint price) public view returns (uint){
        var pair = pairs[pairid];
        return pair.askpricelist.seek(0,price,true);
    }
    function askPriceExists(uint pairid, uint price) public view returns(bool){
        var pair = pairs[pairid];
        return pair.askpricelist.nodeExists(price);
    }
    function getAskDOMPrice(uint pairid, uint prevprice, bool dir) public view returns(uint){
        var pair = pairs[pairid];
        return pair.askpricelist.step(prevprice,dir);    
    }
    function getAskDOMVolume(uint pairid, uint price) public view returns(uint){
        var pair = pairs[pairid];
        uint n = pair.askqueuelist[price].step(0,true);
        if (n==0) return 0;
        uint acc = pair.askdom[price][n].amount;
        while(n!=0){
            n = pair.askqueuelist[price].step(n,true);
            acc = acc.add(pair.askdom[price][n].amount);
        }
        return acc;
    }
    function getFeesRatios() public view returns(uint[2]){
        return [makerfeeratio, takerfeeratio];
    }
    function setFeeRatios(uint maker, uint taker) public onlyOwner returns(bool){
        makerfeeratio = maker;
        takerfeeratio = taker;
        return true;
    }

    function getFeesTotal(uint tokenid) public view onlyOwner returns(uint) {
        return tokens[tokenid].cointotalfees;
    }

    function limitSell_token_eth(uint pairid, uint price, uint prevprice, uint amount, bool ini) public returns (bool) {
       // Entry memory order;
        uint total;
        uint fees;
       // uint codeLength;
        //address sender = msg.sender;
        //success = false;
        if (ini==true)
            require(msg.sender==owner,"Initial only for owner");

        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);

        //var pair = pairs[pairid];
        require(price>pairs[pairid].bestbid || pairs[pairid].bestbid==0,"Invalid ask price");
        
        //uint next;
        var maintoken = tokens[pairs[pairid].mainid];
        if (ini==false){
             pairs[pairid].askdom[price][ordercnt].addr = msg.sender;
            maintoken.coininvestment = maintoken.coininvestment.add(amount);
        }else
             pairs[pairid].askdom[price][ordercnt].addr = address(this);
        pairs[pairid].askdom[price][ordercnt].id = ordercnt;
        pairs[pairid].askdom[price][ordercnt].initial = ini;
        pairs[pairid].askdom[price][ordercnt].amount = amount;
        //pair.askdom[price][ordercnt] = order;

        if (pairs[pairid].askpricelist.nodeExists(price)==true){
            pairs[pairid].askqueuelist[price].push(ordercnt,false);
        }else{
            require(price>prevprice,"Wrong price 1");
            total = pairs[pairid].askpricelist.step(prevprice,true);
            require(price<total,"Wrong price 2");//total=next;
            pairs[pairid].askpricelist.insert(prevprice,price,true);
            pairs[pairid].askqueuelist[price].push(ordercnt,false);
        }

        
        if (msg.sender!=owner){
            fees = amount.mul(makerfeeratio);
            fees = fees.shiftRight(80);
            maintoken.cointotalfees = maintoken.cointotalfees.add(fees);
        }else{
            fees = 0;
        }
        total = fees.add(amount);
        if (ini==false)
            maintoken.tokencontract.transfer_origin(address(this), total);

        ordercnt++;
        if (price<pairs[pairid].bestask || pairs[pairid].bestask==0){
            pairs[pairid].bestask = price;
            emit Quotes(pairid, pairs[pairid].bestask, pairs[pairid].bestbid);
        }
        return true;
    }
    
    function marketBuy_token_eth(uint pairid, uint price, uint amount, uint slippage, bool ini) public payable returns (bool) {
        uint total;
        uint ethacc = 0;

        require( pairs[pairid].bestask!=0);
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);

        if (ini==true)
            require(msg.sender==owner);
        
        if (price!=pairs[pairid].bestask){
            if (price>pairs[pairid].bestask){
                require((price.sub(pairs[pairid].bestask)) < slippage);
            }else{
                require((pairs[pairid].bestask.sub(price)) < slippage);
            }
        }
        uint p = pairs[pairid].bestask;
        uint n;
        uint vols = 0;
        
        do {
            n=0;
            do {
                n = pairs[pairid].askqueuelist[p].step(n, true);
                if (n!=0){
                    if (pairs[pairid].askdom[p][n].amount<=amount.sub(vols)){
                        total = p.mul(pairs[pairid].askdom[p][n].amount);
                        total = total.shiftRight(80);

                        if (pairs[pairid].askdom[p][n].initial==false)
                            require(pairs[pairid].askdom[p][n].addr.send(total));
                        else{
                            tokens[pairs[pairid].baseid].coininvestment = tokens[pairs[pairid].baseid].coininvestment.add(total);
                            tokens[pairs[pairid].mainid].coininvestment = tokens[pairs[pairid].mainid].coininvestment.sub(pairs[pairid].askdom[p][n].amount);
                        }
                        if (ini==false)
                            require(tokens[pairs[pairid].mainid].tokencontract.transfer(msg.sender, pairs[pairid].askdom[p][n].amount));
                        else{
                            tokens[pairs[pairid].mainid].coininvestment = tokens[pairs[pairid].mainid].coininvestment.add(pairs[pairid].askdom[p][n].amount);
                            tokens[pairs[pairid].baseid].coininvestment = tokens[pairs[pairid].baseid].coininvestment.sub(total);
                        }
                        emit TradeFill(pairid, pairs[pairid].askdom[p][n].addr, p, pairs[pairid].askdom[p][n].id, -1*int(pairs[pairid].askdom[p][n].amount));
                        ethacc = ethacc.add(total);

                        vols = vols.add(pairs[pairid].askdom[p][n].amount);
                        pairs[pairid].askqueuelist[p].remove(n);
                    }else{
                        total = p.mul(amount.sub(vols));
                        total = total.shiftRight(80);
                        if (pairs[pairid].askdom[p][n].initial==false)
                            require(pairs[pairid].askdom[p][n].addr.send(total));
                        else{
                            tokens[pairs[pairid].baseid].coininvestment = tokens[pairs[pairid].baseid].coininvestment.add(total);
                            tokens[pairs[pairid].mainid].coininvestment = tokens[pairs[pairid].mainid].coininvestment.sub(amount.sub(vols));
                        }
                        if (ini==false)
                            require(tokens[pairs[pairid].mainid].tokencontract.transfer(msg.sender, amount.sub(vols)));
                        else{
                            tokens[pairs[pairid].mainid].coininvestment = tokens[pairs[pairid].mainid].coininvestment.add(amount.sub(vols));
                            tokens[pairs[pairid].baseid].coininvestment = tokens[pairs[pairid].baseid].coininvestment.sub(total);
                        }
                        emit TradeFill(pairid, pairs[pairid].askdom[p][n].addr, p, pairs[pairid].askdom[p][n].id, -1*int(pairs[pairid].askdom[p][n].amount));
                        ethacc = ethacc.add(total);

                        pairs[pairid].askdom[p][n].amount.sub(amount.sub(vols));
                        vols = vols.add(amount.sub(vols));
                    }
                }
            } while((n!=0) && (vols<amount));
            if (n==0){
                p = pairs[pairid].askpricelist.step(p,true); //ask is true
                require(p!=0,"Not enought market volume");
                require((p.sub(price)) < slippage);
            }
        }while(vols<amount);
        require((p.sub(price)) < slippage);
        if (msg.sender!=owner){
            
            total = p.mul(amount);
            total = total.shiftRight(80);
            total = total.mul(takerfeeratio);
            total = total.shiftRight(80);
            //total is the fee
            require(msg.value.sub(ethacc) > total);
            tokens[pairs[pairid].baseid].cointotalfees.add(total);
            ethacc = ethacc.add(total);
            if (msg.value.sub(ethacc) > 0)
                require(msg.sender.send(msg.value.sub(ethacc)));

        }
        if (p!=pairs[pairid].bestask){
            pairs[pairid].bestask=p;
            emit Quotes(pairid, pairs[pairid].bestask, pairs[pairid].bestbid);
        }
        emit Trade(pairid, msg.sender, p, int(amount));
        return true;
    }

    function tokenFallback(uint tid, address from, uint amount){
        
    }
   
    event Quotes(uint pairid, uint ask, uint bid);    
    event TradeFill(uint indexed pairid, address indexed addr, uint indexed price, uint indexed id, int amount);
    event Trade(uint pairid, address addr, uint price, int amount);
}
