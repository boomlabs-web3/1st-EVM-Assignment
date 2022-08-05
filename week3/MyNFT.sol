// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "hardhat/console.sol";

contract MyNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(address => uint256) minted;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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

    function itemMint(string memory uri) public returns (uint256) {
        // 입력된 TokenURI 확인
        console.log("uri : ", uri);

        address ownerAddress = owner(); //
        address minter = msg.sender;

        //  OWNER 주소 / SENDER 주소 확인
        console.log("ownerAddress : ", ownerAddress);
        console.log("minter : ", minter);

        // 주소당 한번만 민팅 되게 체크
        console.log("minted count ", minted[minter]);
        require(minted[minter] == 0, "Just onetime!!");

        // TokenId 증가
        _tokenIdCounter.increment();
        uint256 newItemId = _tokenIdCounter.current();

        // 호출한 사람에게 민팅
        _mint(minter, newItemId);
        _setTokenURI(newItemId, uri);

        // 전송 전에 잔고 확인
        uint256 balance = balanceOf(minter);
        console.log("balance : ", balance);

        // 0.001 ETH 를 OWNER에게 전송
        emit Transfer(minter, ownerAddress, 0.001 * (10**18));

        //민팅에 성공하면 해당 주소의 민팅 횃수 증가
        minted[minter]++;

        // 신규 TOKEN ID  확인
        console.log("newItemId ==>  ", newItemId);

        return newItemId;
    }
}
