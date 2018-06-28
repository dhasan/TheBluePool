pragma solidity ^0.4.23;
import "../contracts/BlueToken.sol";
import "./SafeMath.sol";
library LibToken {
    using SafeMath for uint;
    struct Token {
        uint id;
        uint coininvestment;
        uint cointotalfees;

        BlueToken tokencontract;
    }  
    function createToken(Token storage self, address taddress) internal returns(bool success){
        self.id = id;
        self.tokencontract = (BlueToken)taddress;//new BlueToken(id, supply, name, desc, transfee);
        success = true;
    }

	function generateTokens(Token storage self, uint amount) internal returns(bool success) {
        require(self.tokencontract.createTokens(amount));
        success = true;
	}

    function destroyTokens(Token storage self, uint amount) internal returns(bool success){
        require(self.tokencontract.destroyTokens(amount));
        success = true;
    }
/*
    function depositInvestment(Token storage self, uint amount) internal returns(bool success){
        self.coininvestment = self.coininvestment.add(amount);
        require(self.tokencontract.transfer_origin(address(this), amount));
        success = true;
    }

    function withdrawInvestment(Token storage self, uint amount) internal returns(bool success) {
        self.coininvestment = self.coininvestment.sub(amount);
        require(self.tokencontract.transfer(msg.sender, amount));
        success = true;
    }

    function getInvestment(Token storage self) internal view returns(uint){
        return self.coininvestment;
    }
*/
/*
    function withdrawFees(Token storage self, uint amount) internal returns(bool success) {
        self.cointotalfees = self.cointotalfees.sub(amount);
        require(self.tokencontract.transfer(msg.sender, amount));
        success = true;
    }
*/
/*
    function withdrawTransFees(Token storage self, uint amount) internal returns(bool success) {
        require(self.tokencontract.widthrawFees(amount, msg.sender));
        success = true;
    }
*/
    function setTransFeeRatio(Token storage self, uint val) internal returns(bool success) {
        require(self.tokencontract.setFeeRatio(val));
        success = true;
    }


}