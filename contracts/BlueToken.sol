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
    
    
    constructor(uint id, uint supply, bytes4 sym, bytes32 desk, uint fee) Owned() public {
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

    function totalSupply() public view returns (uint[2]){
	   return [totalSupply, tokenbalances[owner]];	
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return tokenbalances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        uint fee;
        uint codeLength;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            codeLength := extcodesize(to)
        }

        tokenbalances[msg.sender] = tokenbalances[msg.sender].sub(tokens);
        if (tokenbalances[msg.sender]==0){
            tokenslist.remove(msg.sender);
        }
        if (tokenslist.nodeExists(to)==false){
            tokenslist.push(to,true);
        }
        tokenbalances[to] = tokenbalances[to].add(tokens);
        if ((transferfeeratio!=0) && (msg.sender!=owner)){
            fee = tokens.mul(transferfeeratio);
            fee = fee.shiftRight(80);
            tokenbalances[msg.sender] = tokenbalances[msg.sender].sub(fee);
            transfertotalfees = transfertotalfees.add(fee);
        }
        if(codeLength>0) {
            require(to==owner);
            BluePool receiver = BluePool(to);
            receiver.tokenFallback(tokenid, msg.sender, tokens);
        }
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transfer_origin(address to, uint tokens) public returns (bool success) {
        uint fee;
        uint codeLength;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            codeLength := extcodesize(to)
        }
        require(msg.sender==owner);

        tokenbalances[tx.origin] = tokenbalances[tx.origin].sub(tokens);
        if (tokenbalances[tx.origin]==0){
            tokenslist.remove(tx.origin);
        }
        if (tokenslist.nodeExists(to)==false){
            tokenslist.push(to,true);
        }
        tokenbalances[to] = tokenbalances[to].add(tokens);
        if ((transferfeeratio!=0) && (msg.sender!=owner)){
            fee = tokens.mul(transferfeeratio);
            fee = fee.shiftRight(80);
            tokenbalances[tx.origin] = tokenbalances[tx.origin].sub(fee);
            transfertotalfees = transfertotalfees.add(fee);
        }
        if(codeLength>0) {
            require(to==owner);
            BluePool receiver = BluePool(to);
            receiver.tokenFallback(tokenid, tx.origin, tokens);
        }
        emit Transfer(tx.origin, to, tokens);
        return true;
    }

    function setFeeRatio(uint val) onlyOwner public returns(bool){
        transferfeeratio = val;
        return true;
    }

    function widthrawFees(uint amount, address recv) onlyOwner public returns (bool success){
        transfertotalfees.sub(amount);
        transfer(recv, amount);
        success = true;
    }

    function getFeesTotal() public view returns (uint){
        return transfertotalfees;
    }

    function getTokenOwnersCount() public view returns(uint){
        return tokenslist.sizeOf() - 1; //minus owner
    }
    /*
        Return total amount of invested tokens
    */
    function getTokenTotalInvestment() public view returns(uint){
        address n=0;
        uint acc=0;
        do{
            n = tokenslist.step(n, true);
            if (n!=owner)
                acc = acc.add(tokenbalances[n]);
        }while(n!=0);
        return acc;
    }

    function rewardTokenInvestors(uint ethpertoken, address change) onlyOwner public payable{
        uint value = msg.value;
        address n=0;
        uint amount;
        do{
            n = tokenslist.step(n, true);
            if (n!=owner){
                amount = tokenbalances[n].mul(ethpertoken);
                amount = amount.shiftRight(160);
                require(n.send(amount));
                emit RewardReceived(tokenid, n, amount);
                value = value.sub(amount);
            }
        }while(n!=0);
        require(change.send(value));

    }

    event RewardReceived(uint indexed tid, address indexed addr, uint amount);
    /*
    function approve(address spender, uint tokens) external returns (bool success) {
        return true;
    }

    function transferFrom(address from, address to, uint tokens) external returns (bool success) {
        return true;
    }
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining) {
        return 0;
    }
*/
}
