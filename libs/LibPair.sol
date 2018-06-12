
pragma solidity ^0.4.23;

library LibPair {
	using LibToken for LibToken.Token
    bytes32 constant public VERSION = "LibPair 0.0.1";

    struct Entry{
        uint id;
        address addr;
        uint amount;
        bool initial;
    }

    struct Pair {
        bytes8 name;
        uint mainid;
        uint baseid;
        uint bestask;
        uint bestbid;

        LibCLLu.CLL askpricelist;
        mapping (uint => LibCLLu.CLL) askqueuelist;
        mapping (uint => mapping (uint => Entry)) askdom;

        LibCLLu.CLL bidpricelist;
        mapping (uint => LibCLLu.CLL) bidqueuelist;
        mapping (uint => mapping (uint => Entry)) biddom;

        uint ordercnt;
    }
    

    //function limitSell_token_x(uint pairid, uint price, uint prevprice, uint amount, bool ini) public {
    function limitSell_token_x(Pair storage pair, LibToken.Token storage maintoken, LibToken.Token storage basetoken, uint price, uint prevprice, uint amount, bool ini) internal {

    }
}