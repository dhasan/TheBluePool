pragma solidity ^0.4.23;

import "../libs/LibCLLu.sol";
import "../libs/LibPair.sol";
import "../libs/LibToken.sol";
import "../libs/SafeMath.sol";
import "./Owned.sol";
import "./Feeless.sol";

contract BluePool is Owned,Feeless {
    using SafeMath for uint;
    using LibCLLu for LibCLLu.CLL;    
    using LibToken for LibToken.Token;
    using LibPair for LibPair.Pair;

    uint constant ETHTOKENID = 0;
    uint constant GASTOKENID = 1;

    LibPair.Pair[] pairs;
    LibToken.Token[] tokens;  

    address feelessmaster;

    modifier feelessPair(uint id) {
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

    function setFeelessMaster(address adr) public onlyOwner {
        feelessmaster = adr;
    }

    function getFeelessMaster() public view returns(address){
        return feelessmaster;
    }

    function feelessETHTransfer(address sender, address target, uint256 nonce, bytes sig, bool ext) public payable {

        uint gasUsed = gasleft();
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(prefix, keccak256(target, uint(0), nonce));
        address _msgSender = ECRecovery.recover(hash, sig);
        require(_msgSender == sender);
        require(nonces[sender]++ == nonce);
        
        require(target.call.value(msg.value)());
        gasUsed = gasUsed - gasleft();
        require(tokens[GASTOKENID].transfer_from(sender, feelessmaster, gasUsed));

    }

    function performFeelessTransaction(address sender, address target, bytes data, uint256 nonce, bytes sig, bool ext) public payable {
        require(this == target);
        
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
    
    constructor() Owned(address(0)) public {
        tokens.length = 1;

    }   
    function createToken(address taddress) onlyOwner public returns(uint){
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

    function limitSell(uint pairid, uint orderid, uint price, uint prevprice, uint amount) public feeless feelessPair(pairid){
        require(pairs[pairid].limitSell(tokens[pairs[pairid].mainid], orderid, price, prevprice,amount));
    }

    function modify_ask_order_price(uint pairid, uint orderid, uint price, uint newprice, uint newprevprice) public {
        require(pairs[pairid].modify_ask_order_price(tokens[pairs[pairid].mainid], orderid, price, newprice, newprevprice));
    }

    function marketBuyFull(uint pairid, uint slippage, uint valuep) public payable {
        pairs[pairid].marketBuyFull(tokens[pairs[pairid].mainid], tokens[pairs[pairid].baseid], slippage, valuep);
/*
         uint total;
        uint value = msg.value;
        require( pairs[pairid].bestask!=0);
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            total := extcodesize(caller)
        }
        require(total==0);
        
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
        uint amount;
        if (msg.sender!=pairs[pairid].owner){
            total = value.mul(pairs[pairid].takerfeeratio);
            total = total.shiftRight(80);
            tokens[pairs[pairid].baseid].cointotalfees.add(total);
        }else
            total=0;

        value = value.sub(total);

        do {
            n=0;
            do {
                n = pairs[pairid].askqueuelist[p].step(n, true);
                amount = value.shiftLeft(80);
                amount = value.div(p);
                if (n!=0){
                    
                    if (pairs[pairid].askdom[p][n].amount<=amount.sub(vols)){
                        total = p.mul(pairs[pairid].askdom[p][n].amount);
                        total = total.shiftRight(80);

                        require(pairs[pairid].askdom[p][n].addr.send(total));
                        require(tokens[pairs[pairid].mainid].transfer_from(address(this), msg.sender, pairs[pairid].askdom[p][n].amount));
                        
                        emit TradeFill(pairs[pairid].id, pairs[pairid].askdom[p][n].addr, n, -1*int(pairs[pairid].askdom[p][n].amount));

                        vols = vols.add(pairs[pairid].askdom[p][n].amount);
                        pairs[pairid].askqueuelist[p].remove(n);
                        if (pairs[pairid].askqueuelist[p].sizeOf()==0){
                            pairs[pairid].askpricelist.remove(p);
                        }
                        value = value.sub(total);
                    }else{
                        total = p.mul(amount.sub(vols));
                        total = total.shiftRight(80);

                        require(pairs[pairid].askdom[p][n].addr.send(total));
                        require(tokens[pairs[pairid].mainid].transfer_from(address(this), msg.sender, amount.sub(vols)));
                       
                        emit TradeFill(pairs[pairid].id, pairs[pairid].askdom[p][n].addr, n, -1*int(amount.sub(vols)));

                        pairs[pairid].askdom[p][n].amount.sub(amount.sub(vols));
                        vols = vols.add(amount.sub(vols));
                        value = value.sub(total);
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

        if (p!=pairs[pairid].bestask){
            pairs[pairid].bestask=p;
            emit Quotes(pairs[pairid].id, pairs[pairid].bestask, pairs[pairid].bestbid);
        }
        emit Trade(pairs[pairid].id, msg.sender, p, int(amount));

       // success = true;
*/
    }

    function withdrawFees(uint tid, uint amount, address rcv) onlyOwner public {
        if (tid==0)
            require(rcv.send(amount));
        else
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
        }
        return acc;
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
