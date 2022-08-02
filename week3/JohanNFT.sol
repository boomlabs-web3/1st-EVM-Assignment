// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract JohanNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // 특정 유저가 민팅을 최대 1번까지만 할 수 있도록 기억하는 변수
    mapping(address => uint256) private _mintedOwners;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) payable {}

    // 이전에 민팅을 한 적 있는지 체크하는 함수
    function _newOwner(address owner) internal view virtual returns (bool) {
        return _mintedOwners[owner] == uint256(0);
    }

    // itemMint 함수에 Token URI만 parameter로 받도록 구현
    function itemMint(string memory uri) public payable {
        // 한 번 민팅될 때 수수료를 제외하고 0.001 이더가 같이 차감되게 설정
        require (msg.value >= 0.001 ether, 'Need to pay up!');

        // 민팅은 누구나 가능하지만, 최대 1번까지만 민팅할 수 있게 작성
        require (_newOwner(msg.sender), 'The caller already minted before!');

        // TokenId는 한 번 민팅할 때마다 자동으로 1씩 증가하게 설정
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        // 함수 호출자의 address를 기록해 추후 민팅을 한 적 있는지 체크
        _mintedOwners[msg.sender] = tokenId;

        // 함수 호출자의 address로 NFT가 민팅되도록 설정
        _mint(msg.sender, tokenId);
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
}