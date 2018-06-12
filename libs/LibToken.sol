pragma solidity ^0.4.23;

library LibToken {

    struct Token {
        uint id;
        uint coininvestment;
        uint cointotalfees;
        uint takerfeeratio;
    	uint makerfeeratio;

        BlueToken tokencontract;
    }  
    function createToken(Token storage self, uint id, uint supply, bytes4 name, bytes32 desc, uint transfee) internal returns(bool success){
        self.id = id;
        self.makerfeeratio = makerfee;
        self.takerfeeratio = takerfee;
        self.tokencontract = new BlueToken(id, supply, name, desc, transfee);
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

    function withdrawFees(Token storage self, uint amount) internal returns(bool success) {
        self.cointotalfees = self.cointotalfees.sub(amount);
        require(self.tokencontract.transfer(msg.sender, amount));
        success = true;
    }

    function withdrawTransFees(Token storage self, uint amount) internal returns(bool success) {
        require(self.tokencontract.widthrawFees(amount, msg.sender));
        success = true;
    }

    function setTransFeeRatio(Token storage self, uint val) internal returns(bool success) {
        require(self.tokencontract.setFeeRatio(val));
        success = true;
    }


}