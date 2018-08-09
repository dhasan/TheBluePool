pragma solidity ^0.4.23;

import "../libs/LibCLLu.sol";
import "../libs/LibCLLb8.sol";
import "../libs/LibPair.sol";
import "../libs/LibToken.sol";
import "../libs/SafeMath.sol";
import "./Owned.sol";
//import "./Feeless.sol";

contract BluePool is Owned {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;  
    using LibCLLb8 for LibCLLb8.CLL;  
    using LibToken for LibToken.Token;
    using LibPair for LibPair.Pair;

    uint constant ETHTOKENID = 1;
    uint constant GASTOKENID = 2;

    LibCLLb8.CLL pairslist;
    mapping (bytes8 => LibPair.Pair) pairs;
   
    LibCLLu.CLL tokenslist;
    mapping (uint => LibToken.Token) tokens;

    uint mingasprice;
/*
    modifier feelessPair(bytes8 id) {
        require(msgSender!=address(0));
        if (pairs[id].msgSender != msgSender) {

            pairs[id].msgSender  = msgSender;
            _;
            pairs[id].msgSender  = address(0);
        } else {
            _;
        }
    }

    modifier feelessToken(uint id) {
        require(msgSender!=address(0));
        if (tokens[id].msgSender != msgSender) {

            tokens[id].msgSender  = msgSender;
            _;
            tokens[id].msgSender  = address(0);
        } else {
            _;
        }
    }
*/
    function setMinGasPrice(uint p) public onlyOwner returns(bool success){
        mingasprice = p;
        success = true;
    }

    function getMinGasPrice() public view returns(uint){
        return mingasprice;
    }
/*
    function gasTokenETHTransfer(address sender, address target, uint256 nonce, bytes sig) public payable {
        require(tx.gasprice>=mingasprice);

        uint gasUsed = gasleft();
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(prefix, keccak256(target, uint(0), nonce));
        address _msgSender = ECRecovery.recover(hash, sig);
    
        require(_msgSender == sender);
        require (nonces[sender]++ == nonce);
        require(target.call.value(msg.value)()==false);
        gasUsed = gasUsed - gasleft();
        require(tokens[GASTOKENID].consume_from(sender, gasUsed));

    }

    function gasTokenTransaction(address sender, address target, bytes data, uint256 nonce, bytes sig) public payable {
        require(this == target);
        require(tx.gasprice>=mingasprice);

        uint256 gasUsed = gasleft();
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(prefix, keccak256(target, data, nonce));
        msgSender = ECRecovery.recover(hash, sig);
        require(msgSender == sender);
        require(nonces[msgSender]++ == nonce);
        require(target.call.value(msg.value)(data));
        gasUsed = gasUsed - gasleft();
        require(tokens[GASTOKENID].transfer_from(msgSender, address(this), gasUsed));

        msgSender = address(0);
    }
    */
    constructor() Owned(address(0)) public {
        //tokens.length = 1;
        tokenslist.push(ETHTOKENID, false);


    }   
    function createToken(uint tid, address taddress) onlyOwner public returns(uint){
        LibToken.Token memory token;
        require(tokenslist.nodeExists(tid)==false);
        tokenslist.push(tid, false);
        tokens[tid].id = tid;
        require(tokens[tid].createToken(taddress));
    }  

    function createPair(bytes8 _name, uint m, uint b, uint makerfee, uint takerfee) onlyOwner public {
        LibPair.Pair memory p;
        require(m!=b);
        require(tokenslist.nodeExists(m)==true);
        require(tokenslist.nodeExists(b)==true);
        require(pairslist.nodeExists(_name)==false);

        pairslist.push(_name, false);
        pairs[_name].owner = owner;
        require(pairs[_name].createPair(_name, m, b,makerfee, takerfee));
    }

    function getTokensCount() public view returns(uint){
        return tokenslist.sizeOf();
    }

    function getNextTokenId(uint pid) public view returns(uint){
        return tokenslist.step(pid, true);
    }

    function getPairsCount() public view returns(uint){
        //return tokens.length;
        return pairslist.sizeOf();
    }

    function getNextPairId(bytes8 pid) public view returns(bytes8){
        //return tokens.length;
        return pairslist.step(pid, true);
    }

    function getPairTokenIds(bytes8 pairid) public view returns(uint[2]){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].getPairTokenIds();
    }
    function getPairName(bytes8 pairid) public view returns(bytes8){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].getPairName();
    }

    function getPrices(bytes8 pairid) public view returns(uint[2]){ 
        require(pairslist.nodeExists(pairid)==true);   
    	return pairs[pairid].getPrices();
    }
    function getPrevAsk(bytes8 pairid, uint price) public view returns (uint){ 
        require(pairslist.nodeExists(pairid)==true);    
        return pairs[pairid].getPrevAsk(price);
    }
    function getPrevBid(bytes8 pairid, uint price) public view returns (uint){  
        require(pairslist.nodeExists(pairid)==true);   
        return pairs[pairid].getPrevBid(price);
    }
    function askPriceExists(bytes8 pairid, uint price) public view returns(bool){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].askPriceExists(price);
    }

    function bidPriceExists(bytes8 pairid, uint price) public view returns(bool){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].bidPriceExists(price);
    }

    function getAskDOMPrice(bytes8 pairid, uint prevprice) public view returns(uint){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].getAskDOMPrice(prevprice);    
    }
    function getBidDOMPrice(bytes8 pairid, uint prevprice) public view returns(uint){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].getBidDOMPrice(prevprice);    
    }
    function getAskDOMAmounts(bytes8 pairid, uint price) public view returns(uint){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].getAskDOMAmounts(price);
    }
    function getBidDOMAmounts(bytes8 pairid, uint price) public view returns(uint){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].getBidDOMAmounts(price);
    }
    function getFeesRatios(bytes8 pairid) public view returns(uint[2]){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].getFeesRatios();
    }

   
    function getFeesTotal(uint tokenid) public view onlyOwner returns(uint) {
        require(tokenslist.nodeExists(tokenid)==true);
        return tokens[tokenid].cointotalfees;
    }

    function limitSell(bytes8 pairid, uint orderid, uint price, uint prevprice, uint amount) public {
        require(orderid!=0 && price!=0 && amount!=0);
        require(pairslist.nodeExists(pairid)==true);
        require(pairs[pairid].limitSell(tokens[pairs[pairid].mainid], orderid, price, prevprice,amount));
    }

    function limitBuy(bytes8 pairid, uint orderid, uint price, uint prevprice, uint valuep) public returns (bool success) {
        require(orderid!=0 && price!=0 && valuep!=0);
        require(pairslist.nodeExists(pairid)==true);
        require(pairs[pairid].limitBuy(tokens[pairs[pairid].mainid], tokens[pairs[pairid].baseid], orderid, price, prevprice, valuep));
    }
/*
    function get_ask_order_price(bytes8 pairid, uint orderid) public view returns(uint){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].get_ask_order_price(orderid);
    }

    function get_bid_order_price(bytes8 pairid, uint orderid) public view returns(uint){
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].get_bid_order_price(orderid);
    }

    function get_bid_order_details(bytes8 pairid, uint orderid, uint price) public view returns(address, uint) { //address and amount
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].get_bid_order_details(orderid, price);
    }

    function get_ask_order_details(bytes8 pairid, uint orderid, uint price) public view returns(address, uint) { //address and amount
        require(orderid!=0 && price!=0);
        require(pairslist.nodeExists(pairid)==true);
        return pairs[pairid].get_ask_order_details(orderid, price);
    }

    function modify_ask_order_price(bytes8 pairid, uint orderid, uint price, uint newprice, uint newprevprice) public {
        require(orderid!=0 && price!=0 && newprice!=0);
        require(pairslist.nodeExists(pairid)==true);
        require(pairs[pairid].modify_ask_order_price(tokens[pairs[pairid].mainid], orderid, price, newprice, newprevprice));
    }

    function modify_bid_order_price(bytes8 pairid, uint orderid, uint price, uint newprice, uint newprevprice) public returns (bool success) {
        require(orderid!=0 && price!=0 && newprice!=0);
        require(pairslist.nodeExists(pairid)==true);
        require(pairs[pairid].modify_bid_order_price(orderid, price, newprice, newprevprice));
    }

    function delete_ask_order(bytes8 pairid, uint orderid, uint price) public returns (bool success){
        require(orderid!=0 && price!=0);
        require(pairslist.nodeExists(pairid)==true);
        require(pairs[pairid].delete_ask_order(tokens[pairs[pairid].mainid], orderid, price));
    }

    function delete_bid_order(bytes8 pairid, uint orderid, uint price) public returns (bool success){
        require(orderid!=0 && price!=0);
        require(pairslist.nodeExists(pairid)==true);
        require(pairs[pairid].delete_bid_order(tokens[pairs[pairid].baseid], orderid, price ));
    }
*/

    function marketBuyFull(bytes8 pairid, uint slippage, uint valuep) public payable {
        require(pairslist.nodeExists(pairid)==true);
        pairs[pairid].marketBuyFull(tokens[pairs[pairid].mainid], tokens[pairs[pairid].baseid], slippage, valuep);
    }

    function marketSellFull(bytes8 pairid, uint slippage, uint amountp) public {
        require(pairslist.nodeExists(pairid)==true);
        pairs[pairid].marketSellFull(tokens[pairs[pairid].mainid], tokens[pairs[pairid].baseid], slippage, amountp);
    }

    function withdrawFees(uint tid, uint amount, address rcv) onlyOwner public {
        if (tid==0)
            require(rcv.send(amount));
        else
            require(tokens[tid].withdrawFees(amount, rcv));
    }


    function getMarketDeposit(uint tid, address addr) public view returns(uint){ // this is for pairs library

        uint p;
        uint n;
        uint acc;
        bytes8 i = pairslist.step(0, true);
        //for(i=0;i<pairs.length;i++){
        while(i!=0){
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
                p=0;
                do {
                    p = pairs[i].bidpricelist.step(p, false);
                    n=0;
                    do{
                        n = pairs[i].bidqueuelist[p].step(n, true);
                        if ((pairs[i].biddom[p][n].addr==addr) || (addr==address(0))){
                            acc = acc.add(pairs[i].biddom[p][n].amount);

                        }
                    }while(n!=0);
                }while(p!=0);
            }
            i = pairslist.step(i, true);
        }
        return acc;
    }
   
    event Quotes(uint pairid, uint ask, uint bid);    
    event TradeFill(uint indexed pairid, address indexed addr, uint id, int amount);
    event Trade(uint pairid, address addr, uint price, int amount);
    event PlaceOrder(uint indexed pairid, address indexed addr, uint indexed price, uint id);
}
