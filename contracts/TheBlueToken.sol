pragma solidity ^0.4.23;

import "../libs/SafeMath.sol";
import "../libs/LibCLLa.sol";
import "./ERC20Interface.sol";
import "./Owned.sol";

contract TheBlueToken is ERC20Interface, Owned{
    using SafeMath for uint;
    using LibCLLa for LibCLLa.CLL;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    
    LibCLLa.CLL tokenslist;    
    mapping(address => uint) tokenbalances;
    
    
    constructor(string _sym, string _name) Owned() public {
        symbol = _sym;
        name = _name;
        decimals = 18;
        _totalSupply = 36000 * 10**uint(decimals);
        
        tokenslist.push(owner,true);
        tokenbalances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }    
    function totalSupply() external view returns (uint supply){
	return _totalSupply - tokenbalances[owner];	
    }

    function balanceOf(address tokenOwner) external view returns (uint balance) {
        return tokenbalances[tokenOwner];
    }

    function transfer(address to, uint tokens) external returns (bool success) {
        //require(tokenbalances[msg.sender] >= tokens);
        tokenbalances[msg.sender] = tokenbalances[msg.sender].sub(tokens);
        if (tokenbalances[msg.sender]==0){
            tokenslist.remove(msg.sender);
        }
        if (tokenbalances[to]==0){
            tokenslist.push(to,true);
        }
        tokenbalances[to] = tokenbalances[to].add(tokens);
        
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function generate(uint tokens) onlyOwner external returns (bool success) {
    	_totalSupply = _totalSupply.add(tokens);
        tokenbalances[owner] = tokenbalances[owner].add(tokens);
        return true;
    }
    function approve(address spender, uint tokens) external returns (bool success) {
        return true;
    }

    function transferFrom(address from, address to, uint tokens) external returns (bool success) {
        return true;
    }
    
    function allowance(address tokenOwner, address spender) external view returns (uint remaining) {
        return 0;
    }
}
