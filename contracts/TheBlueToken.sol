pragma solidity ^0.4.23;

import "../libs/SafeMath.sol";
import "./ERC20Interface.sol";
import "./Owned.sol";

contract TheBlueToken is ERC20Interface, Owned{
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    constructor() Owned() public {
        symbol = "TBT";
        name = "The Blue Token Token";
        decimals = 18;
        //_totalSupply = 1000000 * 10**uint(decimals);
        //balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }    
    function totalSupply() external view returns (uint supply){
	return _totalSupply;	
    }

    function balanceOf(address tokenOwner) external view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) external returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
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
