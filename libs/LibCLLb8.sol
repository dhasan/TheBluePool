/*
file:   LibCLL.sol
ver:    0.4.1
updated:18-Dec-2017
author: Darryl Morris
email:  o0ragman0o AT gmail.com

A Solidity library for implementing a data indexing regime using
a circular linked list.

This library provisions lookup, navigation and key/index storage
functionality which can be used in conjunction with an array or mapping.

NOTICE: This library uses internal functions only and so cannot be compiled
and deployed independently from its calling contract.

This software is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See MIT Licence for further details.
<https://opensource.org/licenses/MIT>.

Release Notes:
* Changed to MIT licensing
* minimum Solidity version 0.4.17
* using `view` modifier in place of `constant`
* VERSION type changed from `string` to `bytes32`

*/

pragma solidity ^0.4.23;

// LibCLL using `bytes8` keys
library LibCLLb8 {

    bytes32 constant internal VERSION = "LibCLLu 0.4.1";
    bytes8 constant NULL = 0;
    bytes8 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct CLL{
        mapping (bytes8 => mapping (bool => bytes8)) cll;
    }

    // n: node id  d: direction  r: return node id

    // Return existential state of a list.
    function exists(CLL storage self)
        internal view returns (bool)
    {
        if (self.cll[HEAD][PREV] != HEAD || self.cll[HEAD][NEXT] != HEAD)
            return true;
    }

    function nodeExists(CLL storage self, bytes8 n)
        internal view returns (bool)
    {
        bytes8 a;
        if (exists(self)==false)
            return false;
        else{
            if (self.cll[HEAD][PREV] == n || self.cll[HEAD][NEXT] == n)
                return true;
            else{  
                a = self.cll[n][NEXT];
           
                if (a!=NULL)
                    return true;
                else{
                    a = self.cll[n][PREV];
                    if (a!=NULL)
                        return true;
                    else
                        return false;
                }
            }
        }
    }
    
    // Returns the number of elements in the list
    function sizeOf(CLL storage self)
        internal view returns (uint r)
    {
        bytes8 i = step(self, HEAD, NEXT);
        while (i != HEAD) {
            i = step(self, i, NEXT);
            r++;
        }
        return;
    }

    // Returns the links of a node as and array
    function getNode(CLL storage self, bytes8 n)
        internal view returns (bytes8[2])
    {
        return [self.cll[n][PREV], self.cll[n][NEXT]];
    }

    // Returns the link of a node `n` in direction `d`.
    function step(CLL storage self, bytes8 n, bool d)
        internal view returns (bytes8)
    {
        return self.cll[n][d];
    }

    // Can be used before `insert` to build an ordered list
    // `a` an existing node to search from, e.g. HEAD.
    // `b` value to seek
    // `r` first node beyond `b` in direction `d`
    function seek(CLL storage self, bytes8 a, bytes8 b, bool d)
        internal view returns (bytes8 r)
    {
        r = step(self, a, d);
        while  ((b!=r) && ((b < r) != d)) r = self.cll[r][d];
        return;
    }

    // Creates a bidirectional link between two nodes on direction `d`
    function stitch(CLL storage self, bytes8 a, bytes8 b, bool d) internal {
        self.cll[b][!d] = a;
        self.cll[a][d] = b;
    }

    // Insert node `b` beside existing node `a` in direction `d`.
    function insert (CLL storage self, bytes8 a, bytes8 b, bool d) internal {
        bytes8 c = self.cll[a][d];
        stitch (self, a, b, d);
        stitch (self, b, c, d);
    }
    
    // Remove node
    function remove(CLL storage self, bytes8 n) internal returns (bytes8) {
        if (n == NULL) return;
        stitch(self, self.cll[n][PREV], self.cll[n][NEXT], NEXT);
        delete self.cll[n][PREV];
        delete self.cll[n][NEXT];
        return n;
    }

    // Push a new node before or after the head
    function push(CLL storage self, bytes8 n, bool d) internal {
        insert(self, HEAD, n, d);
    }
    
    // Pop a new node from before or after the head
    function pop(CLL storage self, bool d) internal returns (bytes8) {
        return remove(self, step(self, HEAD, d));
    }
}

