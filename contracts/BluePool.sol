pragma solidity ^0.4.23;

import "../libs/LibCLLu.sol";
import "../libs/LibCLLa.sol";
import "./TheBlueToken.sol";

contract BluePool is TheBlueToken {
    using LibCLLu for LibCLLu.CLL;    
    using LibCLLa for LibCLLa.CLL;
    uint ordercnt;
    
    struct Entry{
        uint id;
        address addr;
        uint amount;
        bool initial;
    }
    uint ethinvestment;
    uint bpsinvestment;    

    uint takerfeeratio;
    uint makerfeeratio;
    uint ethbalance; //fees market profit
    uint bpsbalance; //fees market profit
   
    LibCLLa.CLL ethdepositlist;
    mapping (address => uint) ethdeposits;

    LibCLLa.CLL bpsdepositlist;
    mapping (address => uint) bpsdeposits; 

    uint bestask;
    uint bestbid;

    LibCLLu.CLL askpricelist;
    mapping (uint => LibCLLu.CLL) askqueuelist;
    mapping (uint => mapping (uint => Entry)) askdom;
   
    constructor() TheBlueToken("BPS", "Blue Pool Shares") public {
        ordercnt = 1;
    }     
    function getPrices() external view returns(uint[2]){
    	return [bestask, bestbid];
    }
    function getPrevAsk(uint price) public view returns (uint){
        return askpricelist.seek(0,price,true);
    }
    function askPriceExists(uint price) public view returns(bool){
        return askpricelist.nodeExists(price);
    }
    function getFeesRatios() public view returns(uint[2]){
        return [makerfeeratio, takerfeeratio];
    }
    function setFeeRatios(uint maker, uint taker) public returns(bool){
        makerfeeratio = maker;
        takerfeeratio = taker;
        return true;
    }
    function getAskDOMPrice(uint prevprice, bool dir) public view returns(uint){
        return askpricelist.step(prevprice,dir);    
    }
    function getAskDOMVolume(uint price) public view returns(uint){
        uint n = askqueuelist[price].step(0,true);
        if (n==0) return 0;
        uint acc = askdom[price][n].amount;
        while(n!=0){
            n = askqueuelist[price].step(n,true);
            acc = acc.add(askdom[price][n].amount);
        }
        return acc;
    }

    function limitSell(uint price, uint prevprice, uint amount) public returns (bool success) {
        Entry memory order;
        uint total;
        require(price>bestbid,"Invalid ask price");
        uint next;
        order.addr = msg.sender;
        order.id = ordercnt;
        order.initial = false;
        order.amount = amount;
        askdom[price][ordercnt] = order;

        if (askpricelist.nodeExists(price)==true){
            askqueuelist[price].push(ordercnt,false);
        }else{
            require(price>prevprice,"Wrong price 1");
            next = askpricelist.step(prevprice,true);
            require(price<next,"Wrong price 2");
            askpricelist.insert(prevprice,price,true);
            askqueuelist[price].push(ordercnt,false);
        }
        
        total = price.mul(amount);
        total = total.shiftRight(80);
        total = total.mul(makerfeeratio);
        total = total.shiftRight(80);
        //total is the fee
        if (ethdeposits[msg.sender]>total){
            ethdeposits[msg.sender] = ethdeposits[msg.sender].sub(total);
            if (ethdeposits[msg.sender]==0) ethdepositlist.remove(msg.sender);
            ethbalance = ethbalance.add(total);
        }else{
            total = amount.mul(takerfeeratio);
            total = total.shiftRight(80);
            bpsdeposits[msg.sender] = bpsdeposits[msg.sender].sub(total);
            if (bpsdeposits[msg.sender]==0) bpsdepositlist.remove(msg.sender);
            bpsbalance = bpsbalance.add(total);
        }

        ordercnt++;
        if (price<bestask){
            bestask = price;
            emit Quotes(bestask, bestbid);
        }
        success = true;
    }
    
    function marketBuy(uint price, uint amount, uint slippage) public returns (bool success) {
        uint total;
        require(bestask!=0);
        
        if (price!=bestask){
            if (price>bestask){
                require((price.sub(bestask)) < slippage);
            }else{
                require((bestask.sub(price)) < slippage);
            }
        }
        uint p = bestask;
        uint n;
        uint vols = 0;
        do {
            n=0;
            do {
                n = askqueuelist[p].step(n, true);
                if (n!=0){
                    if (askdom[p][n].amount<=amount.sub(vols)){
                        total = p.mul(askdom[p][n].amount);
                        total = total.shiftRight(80);
                        ethdeposits[msg.sender] = ethdeposits[msg.sender].sub(total);
                        if (ethdeposits[msg.sender]==0) ethdepositlist.remove(msg.sender);
                        if (askdom[p][n].initial==false){
                            if (ethdepositlist.nodeExists(askdom[p][n].addr)==false) ethdepositlist.push(askdom[p][n].addr,true);
                            ethdeposits[askdom[p][n].addr] = ethdeposits[askdom[p][n].addr].add(total);
                            emit TradeFill(askdom[p][n].addr,p,askdom[p][n].id,-1*int(askdom[p][n].amount));
                        }else{
                            ethinvestment.add(total);
                        }
                        if (bpsdepositlist.nodeExists(msg.sender)==false) bpsdepositlist.push(msg.sender,true);
                        bpsdeposits[msg.sender] = bpsdeposits[msg.sender].add(askdom[p][n].amount);
                        vols = vols.add(askdom[p][n].amount);
                        askqueuelist[p].remove(n);
                    }else{
                        total = p.mul(amount.sub(vols));
                        total = total.shiftRight(80);
                        ethdeposits[msg.sender] = ethdeposits[msg.sender].sub(total);
                        if (ethdeposits[msg.sender]==0) ethdepositlist.remove(msg.sender);
                        if (askdom[p][n].initial==false){
                            if (ethdepositlist.nodeExists(askdom[p][n].addr)==false) ethdepositlist.push(askdom[p][n].addr,true);
                            ethdeposits[askdom[p][n].addr] = ethdeposits[askdom[p][n].addr].add(total);
                            emit TradeFill(askdom[p][n].addr,p,askdom[p][n].id,-1*int(amount.sub(vols)));
                        }else{
                            ethinvestment.add(total);
                        }
                        if (bpsdepositlist.nodeExists(msg.sender)==false) bpsdepositlist.push(msg.sender,true);
                        bpsdeposits[msg.sender] = bpsdeposits[msg.sender].add(amount.sub(vols));
                        askdom[p][n].amount.sub(amount.sub(vols));
                        vols = vols.add(amount.sub(vols));
                    }
                }
            } while((n!=0) && (vols<amount));
            if (n==0){
                p = askpricelist.step(p,true); //ask is true
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
            if (ethdeposits[msg.sender]>total){
                ethdeposits[msg.sender] = ethdeposits[msg.sender].sub(total);
                if (ethdeposits[msg.sender]==0) ethdepositlist.remove(msg.sender);
                ethbalance = ethbalance.add(total);        
            }else{
                total = amount.mul(takerfeeratio);
                total = total.shiftRight(80);
                bpsdeposits[msg.sender] = bpsdeposits[msg.sender].sub(total);
                if (bpsdeposits[msg.sender]==0) bpsdepositlist.remove(msg.sender);
                bpsbalance = bpsbalance.add(total);
            }
        }
        if (p!=bestask){
            bestask=p;
            emit Quotes(bestask, bestbid);
        }
        emit Trade(msg.sender, p, int(amount));
        success = true;
    }
    function () public payable {
    
    } 
    event Quotes(uint ask, uint bid);    
    event TradeFill(address addr, uint price, uint id, int amount);
    event Trade(address addr, uint price, int amount);
}
