const { expect } = require("chai");

const { testUtils } = require('hardhat');

const { time, address, constants } = testUtils;

describe("myNFT contract", function () {
    let contractFactory;
    let contract;
    let _name = "myNFT";
    let _symbol = "MYN";
    let owner;
    let account1;
    let account2;
    let tokenURI1 = "https://gateway.pinata.cloud/ipfs/QmNY9AsKWAjm4QLppztGUJxJjofpD6qQQEaQnj9ktWaxTE"

    const FINNEY = 10**15;
    const ETHER = 10**18;

    before(async function () {
        contractFactory = await hre.ethers.getContractFactory("myNFT");
        [owner, account1, account2] = await hre.ethers.getSigners();

        contract = await contractFactory.deploy(_name, _symbol);
        await contract.deployed();

        //console.log('ownerBalance:',ownerBalance);
        //console.log('owner:',owner);
        //console.log('account1:',account1);
        //console.log('account2:',account2);

        console.log("Deploying contracts with the account:", owner.address);

        console.log("Owner Account balance:", (await owner.getBalance()).toString());

        console.log("Account1 balance:", (await account1.getBalance()).toString());
        console.log("Account2 balance:", (await account2.getBalance()).toString());

        //console.log("Contract Account balance:", (await contract.getBalance()).toString());

    });

    describe("Deployment", function () {

        it("Should return the right name and symbol", async function () {
            expect(await contract.name()).to.equal(_name);
            expect(await contract.symbol()).to.equal(_symbol);
          });
        
          it("Mint for Account1", async function () {
        
            console.log("account1 balance:", (await account1.getBalance()).toString());

            // 테스트를 위해 특정 어드레스에 ether 주는 방식 1
            await expect(() =>
                 owner.sendTransaction({ to: account1.address, value: FINNEY })).
                 to.changeEtherBalance(owner, -FINNEY);

            console.log("account1 balance:", (await account1.getBalance()).toString());

            // 테스트를 위해 특정 어드레스에 ether 주는 방식 2 
            // 넉넉하게 2 ether 로 세팅 
            await address.setBalance(account1.address, hre.ethers.utils.parseEther("2"));

            console.log("account1 balance:", (await account1.getBalance()).toString());
            
            //await contract.transfer(account1.address, 50);
            //expect(await contract.balanceOf(account1.address)).to.equal(50);
            // 0.001 로 전달하면 gas fee가 부족해서 실패한다. 
            const amt = hre.ethers.utils.parseEther("0.0011");

            await contract.connect(account1).itemMint(tokenURI1,{value:amt});
            // expect(await DSRVNFT.ownerOf(1)).to.equal(minter);
            console.log("account1 balance:", (await account1.getBalance()).toString());
            
            console.log("account1 minted :",(await contract.connect(account1).minted()));
            
          });

          it("Mint for Account2", async function () {
        
            console.log("account2 balance:", (await account2.getBalance()).toString());
            await address.setBalance(account2.address, hre.ethers.utils.parseEther("2"));
            console.log("account2 balance:", (await account2.getBalance()).toString());
  
            const amt = hre.ethers.utils.parseEther("0.0011");

            await contract.connect(account2).itemMint(tokenURI1,{value:amt});
            console.log("account2 balance:", (await account2.getBalance()).toString());
            
            console.log("account2 minted :",(await contract.connect(account2).minted()));
            
          });

          it("Withdrawl balanace", async function () {
            
            console.log("   owner balance:", (await owner.getBalance()).toString());

            await contract.connect(owner).withdraw();

            console.log("   owner balance:", (await owner.getBalance()).toString());

          });

    });


});