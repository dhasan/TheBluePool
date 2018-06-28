pragma solidity ^0.4.23;

import "../libs/LibCLLu.sol";
import "../libs/LibPair.sol";
import "../libs/LibToken.sol";
import "../libs/SafeMath.sol";
import "./Owned.sol";

contract BluePool is Owned {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;    
    using LibToken for LibToken.Token;
    using LibPair for LibPair.Pair;

    LibPair.Pair[] pairs;
    LibToken.Token[] tokens;  

    constructor() Owned(this) public {
        LibToken.Token memory t;
        tokens.push(t);

    }   
    function createToken(address taddress) onlyOwner public returns(uint){
        LibToken.Token memory t;
        tokens.push(t);
        require(tokens[tokens.length - 1].createToken(tokens.length - 1,taddress));
    }  
    function getTokensCount() public view returns(uint){
        return tokens.length;
    }

    function createPair(bytes8 _name, uint m, uint b, uint makerfee, uint takerfee) onlyOwner public {
        LibPair.Pair memory p;
        require(m!=b);
        require((tokens.length) > m);
        require((tokens.length) > b);
        pairs.push(p);
        require(pairs[pairs.length - 1].createPair(_name, m, b,makerfee, takerfee));
    }
    function generateTokens(uint tid, uint amount) onlyOwner public { 
        require(tid>0);
        require(tokens[tid].generateTokens(amount));
    }
    function destroyTokens(uint tid, uint amount) onlyOwner public { 
        require(tid>0);
        require(tokens[tid].destroyTokens(amount));
    }
    function getPairTokenIds(uint pairid) public view returns(uint[2]){
        return pairs[pairid].getPairTokenIds();
    }
    function getPairName(uint pairid) public view returns(bytes8){
        return pairs[pairid].getPairName();
    }

    function getPrices(uint pairid) public view returns(uint[2]){    
    	return pairs[pairid].getPrices();
    }
    function getPrevAsk(uint pairid, uint price) public view returns (uint){     
        return pairs[pairid].getPrevAsk(price);
    }
    function askPriceExists(uint pairid, uint price) public view returns(bool){
        return pairs[pairid].askPriceExists(price);
    }
    function getAskDOMPrice(uint pairid, uint prevprice) public view returns(uint){
        return pairs[pairid].getAskDOMPrice(prevprice);    
    }
    function getAskDOMVolume(uint pairid, uint price) public view returns(uint){
        return pairs[pairid].getAskDOMVolume(price);
    }
    function getFeesRatios(uint pairid) public view returns(uint[2]){
        return pairs[pairid].getFeesRatios();
    }
    // function setFeeRatios(uint maker, uint taker) public onlyOwner returns(bool){
    //     makerfeeratio = maker;
    //     takerfeeratio = taker;
    //     return true;
    // }

    function getFeesTotal(uint tokenid) public view onlyOwner returns(uint) {
        return tokens[tokenid].cointotalfees;
    }

    function limitSell_token_x(uint pairid, uint price, uint prevprice, uint amount) public {
        pairs[pairid].limitSell_token_x(tokens[pairs[pairid].mainid], tokens[pairs[pairid].baseid], price, prevprice,amount);
    }

    function marketBuyFull_token_eth(uint pairid, uint price, uint slippage) public payable {
        pairs[pairid].marketBuyFull_token_eth(tokens[pairs[pairid].mainid], tokens[pairs[pairid].baseid], price, slippage);
    }
 /*   
    function marketBuy_token_eth(uint pairid, uint price, uint amount, uint slippage, bool ini) public payable {
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
        
        if ((price!=pairs[pairid].bestask) && (slippage!=0) && (price!=0)){
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
                        emit TradeFill(pairid, pairs[pairid].askdom[p][n].addr, pairs[pairid].askdom[p][n].id, -1*int(pairs[pairid].askdom[p][n].amount));
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
                        emit TradeFill(pairid, pairs[pairid].askdom[p][n].addr, pairs[pairid].askdom[p][n].id, -1*int(pairs[pairid].askdom[p][n].amount));
                        ethacc = ethacc.add(total);

                        pairs[pairid].askdom[p][n].amount.sub(amount.sub(vols));
                        vols = vols.add(amount.sub(vols));
                    }
                }
            } while((n!=0) && (vols<amount));
            if (n==0){
                p = pairs[pairid].askpricelist.step(p,true); //ask is true
                require(p!=0,"Not enought market volume");
                if ((slippage!=0) && (price!=0))
                    require((p.sub(price)) < slippage);
            }
        }while(vols<amount);
        if (slippage!=0)
            require((p.sub(price)) < slippage);
        if (msg.sender!=owner){
            
            total = p.mul(amount);
            total = total.shiftRight(80);
            total = total.mul(self.takerfeeratio);
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
    }
*/
  //  function depositInvestmentETH() onlyOwner public payable{
  //      tokens[0].coininvestment = tokens[0].coininvestment.add(msg.value);
  //  }
    //sold tokens already in the owner address
/*
    function withdrawInvestmentETH(uint amount, address rcv) onlyOwner public {
        require(owner.send(amount));
        tokens[0].coininvestment = tokens[0].coininvestment.sub(amount);
    }*/

 //   function depositInvestment(uint tid, uint amount) public { 
 //       require(tid>0);
 //       require(tokens[tid].depositInvestment(amount));
 //   }
 //   function withdrawInvestment(uint tid, uint amount) onlyOwner public { 
  //      require(tid>0);
  //      require(tokens[tid].withdrawInvestment(amount));
  //  }

 //   function getInvestment(uint tid) public view returns(uint) { 
 //       require(tid>0);
 //       return tokens[tid].getInvestment();
 //   }
/*
    function withdrawFeesETH(uint amount) onlyOwner public {
        require(owner.send(amount));
        tokens[0].cointotalfees = tokens[0].cointotalfees.sub(amount);
    }*/
/*
    function withdrawFees(uint tid, uint amount) onlyOwner public {
        require(tid>0);
        require(tokens[tid].withdrawFees(amount));
    }
*/
   // function withdrawTransFees(uint tid, uint amount) onlyOwner public {
   //     require(tid>0);
   //     require(tokens[tid].withdrawTransFees(amount));
   // }

    function setTransFeeRatio(uint tid, uint val) onlyOwner public {
        require(tid>0);
        require(tokens[tid].setTransFeeRatio(val));
    }

    function tokenFallback(uint tid, address from, uint amount) public {
        
    }

    function getMarketDeposit(uint tid, address addr) public view returns(uint){ // this is for pairs library
        uint i;
        uint p;
        uint n;
        uint acc;
        for(i=0;i<pairs.length;i++){
            if (pairs[i].mainid==tid){
                p=0;
                do {
                    p = pairs[i].askpricelist.step(p, true);
                    n=0;
                    do{
                        n = pairs[i].askqueuelist[p].step(n, true);
                        if ((pairs[i].askdom[p][n].addr==addr) || (addr==address(0)))
                            acc = acc.add(pairs[i].askdom[p][n].amount);
                    }while(n!=0);
                }while(p!=0);
            }else if  (pairs[i].baseid==tid){
                //TODO: add biddom
            }
        }
        return acc;
    }

    function rewardMarketDeposits(uint tid, uint ethpertoken, address change) onlyOwner public payable { // this is for pairs library
        uint i;
        uint p;
        uint n;
       // uint acc;
        uint amount;
        uint value = msg.value;
        for(i=0;i<pairs.length;i++){
            if (pairs[i].mainid==tid){
                p=0;
                do {
                    p = pairs[i].askpricelist.step(p, true);
                    n=0;
                    do{
                        n = pairs[i].askqueuelist[p].step(n, true);
                        if ((pairs[i].askdom[p][n].addr!=address(this))){
                            amount = pairs[i].askdom[p][n].amount.mul(ethpertoken);
                            amount = amount.shiftRight(160);
                            require(pairs[i].askdom[p][n].addr.send(amount));
                            value = value.sub(amount);
                        }                            
                    }while(n!=0);
                }while(p!=0);
            }else if  (pairs[i].baseid==tid){
                //TODO: add biddom
            }
        }
        require(change.send(value));
        
    }

    function calculateEthPerToken(uint investdeposit, uint marketdeposit, uint eths) public pure returns(uint){
        uint acc = investdeposit.add(marketdeposit);
        acc = eths.div(acc);
        return acc;
    }
   
    event Quotes(uint pairid, uint ask, uint bid);    
    event TradeFill(uint indexed pairid, address indexed addr, uint id, int amount);
    event Trade(uint pairid, address addr, uint price, int amount);
    event PlaceOrder(uint indexed pairid, address indexed addr, uint indexed price, uint id);
}
