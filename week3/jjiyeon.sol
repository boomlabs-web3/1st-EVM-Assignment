// SPDX-License-Identifier: MIT 
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract journeyNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256) _mintedId;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}
    //민팅아이디 확인
    function _isMinted(address owner) external view returns (bool) {
        return _mintedId[owner] != uint256(0)
    }
    //- 이 함수는 오직 TokenURI 데이터만을 받는 함수입니다.
    function itemMint(string memory uri) public payable{
        // - 민팅은 누구나 가능하지만, 최대 1번까지만 민팅할 수 있게 작성해주세요.
        require(_isMinted(msg.sender),"already minted");
        // - 한 번 민팅될 때 수수료를 제외하고 0.001 이더가 같이 차감되게 설정해주세요.
        
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _mintedId[msg.sender] = tokenId;

        // - 이 함수를 호출한 사람의 주소로 NFT가 민팅되게 설정해주세요.
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