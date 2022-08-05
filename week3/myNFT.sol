// SPDX-License-Identifier: MIT 
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract myNFT is ERC721 {
    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256) mintCount;
    constructor () public {
        owner = msg.sender ;

    } 
    function itemMint(string memory uri){
        // 최대 1번 민팅 제한, 민팅시 잔고부족하면 거절
        require(mintCount(msg.sender) < 1 );
        require(balances[msg.sender] > 0.001 );

        // 1번 민팅할때마다 TokenId 1씩 증가
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        // 민팅기능
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        // 민팅 시, 잔고 0.001 차감
        balances[msg.sender] -= 0.001; 
    }
}