// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract myNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    mapping (address => uint) mintlimit;
    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function mintToken(address to, string memory uri) public onlyOwner {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function itemMint(string memory uri) payable{
        /// minting 횟수 1회 제한
        require(mintlimit[msg.sender] <=1);            
        /// 호출자에게 token을 mint함.
        mintToken(msg.sender, uri);
        mintlimit[msg.sender]++;
        
        /// itemMint 시 0.001 ether 만큼이 빠져나감.
        balanceof(msg.sender) -= 0.001 ether;
        /// owner의 지갑 주소로 이더 송금
        payable(owner()).transfer(0.001 ether);

        

    }
}