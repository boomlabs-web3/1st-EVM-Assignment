// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "hardhat/console.sol";

contract MyNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokeIdCounter;

    // mint 시 차감되는 가격
    uint256 price = 0.001 * 10 ** 18;

    // 민팅 여부를 위한 변수
    // key : sender address
    // value : tokenId
    mapping(address => uint256) holderList;

    // 내 지갑 주소
    address myWalletAddress = 0xf6Bd559CAa721cAc307DCeB6194AF0B8fD175749;

    constructor (string memory name, string memory symbol) ERC721(name, symbol) {}

    function mintNFT() public {
        require(holderList[msg.sender] == 0, "This Address have other nft.");
        _tokeIdCounter.increment();
        uint256 tokenId = _tokeIdCounter.current();
        holderList[msg.sender] = tokenId;
        _mint(msg.sender, tokenId);
    }

    // TokenURI 데이터만을 받는 함수
    // 이 함수를 호출한 사람의 주소로 NFT 민팅
    // 한 번 민팅될 때 수수료를 제외하고 0.001 이더 차감
    // 민팅 누구나 가능하지만, 최대 1번까지만 민팅
    function itemMint(string memory uri) public payable {
        // 민팅 여부 확인
        require(holderList[msg.sender] == 0, "This Address have other nft.");
        // 호출자 0.001 이더 이상 확인
        require(msg.value >= price, "Not enough ether");
        _tokeIdCounter.increment();
        uint256 tokenId = _tokeIdCounter.current();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        // 한 번만 민팅하게 하기위해 holderList에 기록
        holderList[msg.sender] = tokenId;
        // 내 지갑에 0.001 이더 전송
        // payable(owner()).transfer(price);
        payable(myWalletAddress).transfer(price);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
          super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

}