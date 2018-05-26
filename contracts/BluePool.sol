pragma solidity ^0.4.23;

import "../libs/LibCLLu.sol";
import "../libs/LibCLLa.sol";
import "./TheBlueToken.sol";

contract BluePool is TheBlueToken {
    using LibCLLu for LibCLLu.CLL;    
    using LibCLLa for LibCLLa.CLL;
    
    struct Entry{
        address addr;
        uint amount;
        bool initial;
    }
    uint ethinvestment;
    uint bpsinvestment;    

    uint takerfeeratio;
    uint makerfeeratio;
    uint ethbalance;
    uint bpsbalance;
   
    LibCLLa.CLL ethdepositlist;
    mapping (address => uint) ethdeposits;

    LibCLLa.CLL bpsdepositlist;
    mapping (address => uint) bpsdeposits; 

    uint bestask;
    uint bestbid;

    LibCLLu.CLL askpricelist;
    mapping (uint => LibCLLu.CLL) askqueuelist;
    mapping (uint => mapping (uint => Entry)) askdom;
    mapping (uint => uint) askqueuetotal;
    
    function getPrices() external view returns(uint[2]){
    	return [bestask, bestbid];
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
                            if (ethdeposits[askdom[p][n].addr]==0) ethdepositlist.push(askdom[p][n].addr,true);
                            ethdeposits[askdom[p][n].addr] = ethdeposits[askdom[p][n].addr].add(total);
                        }else{
                            ethinvestment.add(total);
                        }
                        bpsdeposits[msg.sender] = bpsdeposits[msg.sender].add(askdom[p][n].amount);
                        vols = vols.add(askdom[p][n].amount);
                        askqueuelist[p].remove(n);
                    }else{
                        total = p.mul(amount.sub(vols));
                        total = total.shiftRight(80);
                        ethdeposits[msg.sender] = ethdeposits[msg.sender].sub(total);
                        if (ethdeposits[msg.sender]==0) ethdepositlist.remove(msg.sender);
                        if (askdom[p][n].initial==false){
                            if (ethdeposits[askdom[p][n].addr]==0) ethdepositlist.push(askdom[p][n].addr,true);
                            ethdeposits[askdom[p][n].addr] = ethdeposits[askdom[p][n].addr].add(total);
                        }else{
                            ethinvestment.add(total);
                        }
                        bpsdeposits[msg.sender] = bpsdeposits[msg.sender].add(amount.sub(vols));
                        askdom[p][n].amount.sub(amount.sub(vols));
                        vols = vols.add(amount.sub(vols));
                        
                    }
                }
            } while((n!=0) && (vols<amount));
            if (n==0){
                p = askpricelist.step(p,true); //ask is true
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
                ethbalance = ethbalance.add(total);        
            }else{
                total = amount.mul(takerfeeratio);
                total = total.shiftRight(80);
                bpsdeposits[msg.sender] = bpsdeposits[msg.sender].sub(total);
                bpsbalance = bpsbalance.add(total);
            }
        }
        
        success = true;
    }
    
    
}
