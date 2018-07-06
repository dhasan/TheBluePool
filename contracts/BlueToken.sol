pragma solidity ^0.4.23;

import "../libs/SafeMath.sol";
import "../libs/LibCLLa.sol";
import "./ERC20Interface.sol";
import "./Owned.sol";
import "./BluePool.sol";

contract BlueToken is ERC20Interface, Owned{
    using SafeMath for uint;
    using LibCLLa for LibCLLa.CLL;

    bytes4 public symbol;
    bytes32 public name;
    uint8 public decimals;
    uint public totalSupply;

    uint tokenid;

    uint transferfeeratio;
    uint transfertotalfees;
    
    LibCLLa.CLL tokenslist;    
    mapping(address => uint) tokenbalances;

    mapping(address => bool)[] claimed;
    uint[] ethpertoken;

    uint capital;
   // uint surplus;
    
    constructor(uint id, uint supply, bytes4 sym, bytes32 desk, uint fee, address _market) Owned(_market) public {
        symbol = sym;
        name = desk;
        decimals = 18;
        totalSupply = supply * 10**uint(decimals);
        
        if (tokenslist.nodeExists(owner)==false){
            tokenslist.push(owner,true);
        }
        tokenbalances[owner] = totalSupply;
        tokenid= id;
        transferfeeratio = fee;
        emit Transfer(address(0), owner, totalSupply);
    }  

    function createTokens(uint amount) public onlyOwner returns(bool success) {
        totalSupply = totalSupply.add(amount * 10**uint(decimals));
        tokenbalances[owner] = tokenbalances[owner].add(amount * 10**uint(decimals));
        success = true;
    }  

    function destroyTokens(uint amount) public onlyOwner returns(bool success) {
        totalSupply = totalSupply.sub(amount* 10**uint(decimals));
        tokenbalances[owner] = tokenbalances[owner].sub(amount* 10**uint(decimals));
        success = true;
    }

    function totalSupply() public view returns (uint){
	   return totalSupply;	
    }

    function getAwailableOf(address adr) public view returns(uint){
        return awailable[adr];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return tokenbalances[tokenOwner];
    }

    function tryReward(address adr) private returns(bool success){
        uint val;

        if (ethpertoken.length==0){
            success = false;
            return;

        }
        int i = int(ethpertoken.length - 1);
        uint acc=0;
        while((claimed[i][adr]==false) && i>=0){
            val = tokenbalances[adr].mul(ethpertoken[i]);
            val = val.shiftRight(32);
            acc = acc.add(val);
            claimed[i][adr] = true;
            i--;
        }
        if (acc!=0){
            require(adr.send(acc));
            event RewardReceived(tokenid, adr, acc);
        }
        success=true;
    }

    function widthrawReward(address adr) public {
        require(tryReward(adr));
    }

    function getAwailable(address adr) public view returns(uint) {
        require
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        uint fee;
        if ((msg.sender!=owner) && (msg.sender!=market))
            tryReward(msg.sender);
        if ((to!=owner) && (to!=market))
            tryReward(to);

        if (((msg.sender==owner) || (msg.sender==market)) && ((to!=owner) && (to!=market)))
            capital = capital.add(tokens);
        if (((to==owner) || (to==market)) && ((msg.sender!=owner) && (msg.sender!=market)))
            capital = capital.sub(tokens);

        tokenbalances[msg.sender] = tokenbalances[msg.sender].sub(tokens);
        if (tokenbalances[msg.sender]==0){
            tokenslist.remove(msg.sender);
        }
        if (tokenslist.nodeExists(to)==false){
            tokenslist.push(to,true);
        }
        tokenbalances[to] = tokenbalances[to].add(tokens);
        if ((transferfeeratio!=0) && (msg.sender!=owner) && (msg.sender!=market)){
            fee = tokens.mul(transferfeeratio);
            fee = fee.shiftRight(80);
            tokenbalances[msg.sender] = tokenbalances[msg.sender].sub(fee);
            tokenbalances[this] = tokenbalances[this].add(fee);
            transfertotalfees = transfertotalfees.add(fee);
        }

        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transfer_from(address from, address to, uint tokens) onlyMarket public returns (bool success) {
        
        if (from!=owner) && (from!=market))
            tryReward(from);
        if ((to!=owner) && (to!=market))
            tryReward(to);

        if (((from==owner) || (from==market)) && ((to!=owner) && (to!=market)))
            capital = capital.add(tokens);
        if (((to==owner) || (to==market)) && ((from!=owner) && (from!=market)))
            capital = capital.sub(tokens);

        tokenbalances[from] = tokenbalances[from].sub(tokens);
        if (tokenbalances[from]==0){
            tokenslist.remove(from);
        }
        if (tokenslist.nodeExists(to)==false){
            tokenslist.push(to,true);
        }
        tokenbalances[to] = tokenbalances[to].add(tokens);
        

        emit Transfer(from, to, tokens);
        return true;
    }

    function setFeeRatio(uint val) onlyOwner public returns(bool){
        transferfeeratio = val;
        return true;
    }

    function widthrawFees(uint amount, address recv) onlyOwner public returns (bool success){
        transfertotalfees = transfertotalfees.sub(amount);
        transfer_from(address(this), recv, amount);
        success = true;
    }

    function getFeesTotal() public view returns (uint){
        return transfertotalfees;
    }

    function getTokenOwnersCount() public view returns(int){
        return int(tokenslist.sizeOf()); //minus owner and market
    }

    function getTokenOwner() public view returns(address){
        return owner;
    }
    /*
        Return total amount of invested tokens
    */
    function getTokenTotalInvestment() public view returns(uint[2]){
        address n=0;
        uint acc=0;
        uint cnt=0;
        do{
            if ((n!=owner) && (n!=market) && (n!=0)){
                n = tokenslist.step(n, true);
                acc = acc.add(tokenbalances[n]);
                cnt++;
            }
        }while(n!=0);
        return [acc, cnt];
    }

    function getCapital() public view returns(uint) {
        return capital;
    }

    function rewardTokenInvestors() onlyOwner public payable{
        uint value = msg.value.shiftLeft(32);
        uint ethpt = value.div(capital);
        
        ethpertoken.push(ethpt);
        claimed.length++;
        require(ethpertoken.length == claimed.length);
        emit Dividents(tokenid, ethpt, msg.value);

    }

    function () payable{
        revert();
    }

    
    event Dividents(uint indexed tid, uint ethpertoken, uint value);
    event RewardReceived(uint indexed tid, address indexed addr, uint amount);
    
}
