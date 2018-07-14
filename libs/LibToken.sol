pragma solidity ^0.4.23;
//import "../contracts/BlueToken.sol";
import "./SafeMath.sol";
library LibToken {
    using SafeMath for uint;
    struct Token {
        uint id;
        //uint coininvestment;
        uint cointotalfees;

        address tokencontract;
        address msgSender;
    }  
    function createToken(Token storage self, address taddress) public returns(bool success){
        //self.id = id;
        self.tokencontract = (taddress);//new BlueToken(id, supply, name, desc, transfee);
        success = true;
    }
/*
	function generateTokens(Token storage self, uint amount) public returns(bool success) {
        require(self.tokencontract.createTokens(amount));
        success = true;
	}

    function destroyTokens(Token storage self, uint amount) public returns(bool success){
        require(self.tokencontract.destroyTokens(amount));
        success = true;
    }
    */
/*
    function depositInvestment(Token storage self, uint amount) public returns(bool success){
        self.coininvestment = self.coininvestment.add(amount);
        require(self.tokencontract.transfer_origin(address(this), amount));
        success = true;
    }

    function withdrawInvestment(Token storage self, uint amount) public returns(bool success) {
        self.coininvestment = self.coininvestment.sub(amount);
        require(self.tokencontract.transfer(msg.sender, amount));
        success = true;
    }

    function getInvestment(Token storage self) public view returns(uint){
        return self.coininvestment;
    }
*/
    function consume_from(Token storage self, address from, uint amount) public returns(bool success){
        require(self.tokencontract.call(bytes4(keccak256("consume_from(address,uint)")),from,amount));
        success = true;
    }
    
    function transfer_from(Token storage self, address from, address to, uint amount) public returns(bool success){
        //require(BlueToken(self.tokencontract).transfer_from(from, to, amount));
        require(self.tokencontract.call(bytes4(keccak256("transfer_from(address,address,uint)")),from,to,amount));
        success = true;
    }
    function withdrawFees(Token storage self, uint amount, address rcv) public returns(bool success) {
        self.cointotalfees = self.cointotalfees.sub(amount);
        //require(BlueToken(self.tokencontract).transfer_from(address(this), rcv, amount));
        require(self.tokencontract.call(bytes4(keccak256("transfer_from(address,address,uint)")),address(this),rcv,amount));
        success = true;
    }

/*
    function withdrawTransFees(Token storage self, uint amount) public returns(bool success) {
        require(self.tokencontract.widthrawFees(amount, msg.sender));
        success = true;
    }
*/
/*
    function setTransFeeRatio(Token storage self, uint val) public returns(bool success) {
        require(self.tokencontract.setFeeRatio(val));
        success = true;
    }
    */


}
