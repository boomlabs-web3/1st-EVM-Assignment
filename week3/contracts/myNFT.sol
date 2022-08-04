//SPDX-License-Identifier: MIT 

// Solidity 0.8.14 is not fully supported yet. You can still use Hardhat, but some features, like stack traces, might not work correctly.
// 0.8.14 는 hardhat 에서 모두 지원이 안되어서 0.8.9 로 바꿨습니다.
pragma solidity ^0.8.9;

// 아래 항목들을 import 하기 위해서 hardhat-upgrades 를 install 해야 했습니다.
// 참고 : https://docs.openzeppelin.com/upgrades-plugins/1.x/hardhat-upgrades
// 참고 : https://forum.openzeppelin.com/t/importing-oz-contracts-with-hardhat/8588
// npm install --save-dev @openzeppelin/hardhat-upgrades
// npm install --save-dev @nomiclabs/hardhat-ethers ethers
// npm install --save-dev @openzeppelin/contracts
// https://github.com/theNvN/hardhat-test-utils
// npm install --save-dev hardhat-test-utils hardhat ethers @nomiclabs/hardhat-ethers
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// 참고 : https://bitofanibble.com/how-to-create-an-nft-contract-with-solidity/

contract myNFT is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
        
    uint256 private _mintPrice = 0.001 ether;// finney; //0.001 ether;

    // 민팅 횟수 기록하기 위한 매핑 변수 
    // ( 민팅 여부만 기록하는 것보다 나중에 2회 이상 허용하기 위해서 uint로 사용 )
    mapping(address => uint) private _mintCounts;

    constructor(string memory name, string memory symbol) 
        ERC721(name, symbol) {
            // 여기서 owner() 등이 자동으로 설정 됨
            //address public _owner; 를 만들 필요 없음.
        }

    // 민트 성공 메시지
    event Minted(address _minter,uint256 _tokenId);

    modifier oneMintOnly {
        // 이미 1번이상 민팅한 사람인지 확인 
        require(_mintCounts[msg.sender]<1, "not allowed to mint more than once"); 
        _;
    }
    modifier costs(uint _amount) {
        // 0.001 eth 있는지 확인 
        require(msg.value > _amount, "not enough balance to mint");
        _;
    }
// - itemMint라는 함수를 생성해주세요.
//     - 이 함수는 오직 TokenURI 데이터만을 받는 함수입니다.
//     - 이 함수를 호출한 사람의 주소로 NFT가 민팅되게 설정해주세요.
//     - 한 번 민팅될 때 수수료를 제외하고 0.001 이더가 같이 차감되게 설정해주세요.
//     - 민팅은 누구나 가능하지만, 최대 1번까지만 민팅할 수 있게 작성해주세요.
    function itemMint(string memory uri) public payable oneMintOnly costs(_mintPrice) {
        
        // 민팅 횟수 기록 
        _mintCounts[msg.sender] += 1;       
        // TODO 민팅한 사람을 기록해 두면 관리상 용이할 것 같은데... 그럴 필요 있을까?
        // 0.001 eth 차감         
        // 사용자에게 잔돈 전달 ㅎ ( return change to the sender )
        // ( change 를 계산해서 transfer 하는 방식 넘 어색하다.;; )
        // 이렇게 하는게 맞는지 아직 모르겠다.
        uint256 change = msg.value - _mintPrice;
        payable(msg.sender).transfer(change);

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        // TODO tokenId 가 발급 제한 MAX를 넘지 않는지 체크해야 할 것 같다. 

        // safeMint가 더 좋은 것 같아서...( 차이는 아직 모름 )
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        
        emit Minted(msg.sender,tokenId);
    }

    // test 를 위해서 민트 여부 체크 함수 추가
    function minted() public view returns(bool) {
        if ( _mintCounts[msg.sender]>=1 ) {
            return true;
        }
        return false;
    }

    // override 를 해야 합니다.
	function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
		    super._burn(tokenId);
    }

    // override 를 해야 합니다.
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // TODO 수익금 챙기는 거. 그냥 해 봄
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
