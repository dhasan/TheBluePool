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

    constructor() Owned(address(0)) public {
        //LibToken.Token  memory t;
        //tokens.push(t);
        tokens.length = 1;

    }   
    function createToken(address taddress) onlyOwner public returns(uint){
        //LibToken.Token memory t;
        //tokens.push(t);
        tokens.length++;
        require(tokens[tokens.length - 1].createToken(tokens.length - 1,taddress));
    }  

    function createPair(bytes8 _name, uint m, uint b, uint makerfee, uint takerfee) onlyOwner public {
        //LibPair.Pair memory p;
        require(m!=b);
        require((tokens.length) > m,"Invalid main token id");
        require((tokens.length) > b);
       // p.owner = owner;
       // pairs.push(p);
        pairs.length++;
        pairs[pairs.length - 1].owner = owner;
        require(pairs[pairs.length - 1].createPair(_name, m, b,makerfee, takerfee));
    }

    function getTokensCount() public view returns(uint){
        return tokens.length;
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
    function getPrevBid(uint pairid, uint price) public view returns (uint){     
        return pairs[pairid].getPrevBid(price);
    }
    function askPriceExists(uint pairid, uint price) public view returns(bool){
        return pairs[pairid].askPriceExists(price);
    }

    function bidPriceExists(uint pairid, uint price) public view returns(bool){
        return pairs[pairid].bidPriceExists(price);
    }

    function getAskDOMPrice(uint pairid, uint prevprice) public view returns(uint){
        return pairs[pairid].getAskDOMPrice(prevprice);    
    }
    function getBidDOMPrice(uint pairid, uint prevprice) public view returns(uint){
        return pairs[pairid].getBidDOMPrice(prevprice);    
    }
    function getAskDOMAmounts(uint pairid, uint price) public view returns(uint){
        return pairs[pairid].getAskDOMAmounts(price);
    }
    function getBidDOMAmounts(uint pairid, uint price) public view returns(uint){
        return pairs[pairid].getBidDOMAmounts(price);
    }
    function getFeesRatios(uint pairid) public view returns(uint[2]){
        return pairs[pairid].getFeesRatios();
    }

    function get_ask_order_price(uint pairid, uint orderid) public view returns(uint){
        return pairs[pairid].get_ask_order_price(orderid);
    }

    function get_bid_order_price(uint pairid, uint orderid) public view returns(uint){
        return pairs[pairid].get_bid_order_price(orderid);
    }

    function getFeesTotal(uint tokenid) public view onlyOwner returns(uint) {
        return tokens[tokenid].cointotalfees;
    }
/*
    function limitSell_token_x(uint pairid, uint price, uint prevprice, uint amount) public {
        require(pairs[pairid].limitSell_token_x(tokens[pairs[pairid].mainid], price, prevprice,amount));
    }

    function modify_ask_order_price(uint pairid, uint orderid, uint price, uint newprice, uint newprevprice) public {
        require(pairs[pairid].modify_ask_order_price(tokens[pairs[pairid].mainid], orderid, price, newprice, newprevprice));
    }

    function marketBuyFull_token_eth(uint pairid, uint price, uint slippage) public payable {
        require(pairs[pairid].marketBuyFull_token_eth(tokens[pairs[pairid].mainid], tokens[pairs[pairid].baseid], price, slippage));
    }
*/
    function withdrawFeesETH(uint amount, address rcv) onlyOwner public {
        
        tokens[0].cointotalfees = tokens[0].cointotalfees.sub(amount);
        require(rcv.send(amount));
    }

    function withdrawFees(uint tid, uint amount, address rcv) onlyOwner public {
        require(tid>0);
        require(tokens[tid].withdrawFees(amount, rcv));
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
