pragma solidity ^0.4.23;

import { ECRecovery } from "../libs/ECRecovery.sol";


contract Feeless {
    
    address internal msgSender;
    mapping(address => uint256) public nonces;
    
    modifier feeless {
        if (msgSender == address(0)) {
            msgSender = msg.sender;
            _;
            msgSender = address(0);
        } else {
            _;
        }
    }
   
}