pragma solidity ^0.4.23;

contract Owned {
    address public owner;
    address public newOwner;

    address public market;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor(address _market) public {
        market = _market
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyMarket {
        require(msg.sender == market);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
