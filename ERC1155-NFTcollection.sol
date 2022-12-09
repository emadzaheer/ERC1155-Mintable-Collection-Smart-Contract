// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol"; 
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol"; //supply tracking
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract MTKFinale is ERC1155, Ownable, Pausable, ERC1155Supply, PaymentSplitter {
    uint256 public publicPrice = 0.007 ether;           
    uint256 public maxSupply = 3000;                        //max supply per token
    uint256 allowListMintPrice = 0.003 ether;               // discounted price for allow list addresses.
    bool public PublicMintOpen = false;
    bool public AllowListMintOpen = false;
    mapping(address=> bool) public m_allowList;     
    mapping(address => mapping(uint256 => uint256)) public m_maxTokenTypePerWallet; 

    //@param _payees is an array which takes input in the form: ["address1", "address2"]
    //@param _shares is an array. input form: [uint, uint] ///out of 100% 
    constructor(
        address[] memory _payees,                                         
        uint256[] memory _shares
    )
        ERC1155("ipfs://Qmaa6TuP2s9pSKczHF4rwWhTKUdygrrDs8RmYYqCjP3Hye/")
        PaymentSplitter(_payees, _shares)
    {}


    function setURI(string memory newuri) public onlyOwner { //can change URI using this func
        _setURI(newuri);
    }


    function pause() public onlyOwner {
        _pause();
    }


    function unpause() public onlyOwner {
        _unpause();
    }


    function uri(uint256 _id) public view virtual override returns (string memory) {     //copied from ERC1155.sol
        require(exists(_id), "URI: does not exist");
        return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json" ));
    }

    //@param: id: the unique id for each token.
    //@param: amount: the num of copies for token with (id). 
    function mint_public(uint256 id, uint256 amount) public payable {
        //removed onlyOwner bec we want public to mint    
        require(PublicMintOpen, "Public minting has not been opened yet");
        require(id <= 3, "id does not exist");
        require(totalSupply(id) + amount <= maxSupply, "specify a num that makes sense keeping the max supply in mind");  //emphasis on ts(id): from 1155supply, amount should be added to keep it uner max supply. eg max supply is only 20 and we mint amount of 3000. lol  
        require(msg.value >= publicPrice * amount, "insufficient funds for this operation!");
        require(m_maxTokenTypePerWallet[msg.sender][id] + amount < 3, "one address cannot have more than 3 copies");
        _mint(msg.sender, id, amount, "");
        m_maxTokenTypePerWallet[msg.sender][id] += amount;
    }


    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner{
        _mintBatch(to, ids, amounts, data);
    }


    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    //not needed if payment splitter is used/
    // function withdraw(address _addr) external payable onlyOwner{          //owner's way to extract money from the contract balance.
    //     uint256 balance = address(this).balance;
    //     payable(_addr).transfer(balance);
    // }


    function allowListMint(uint256 id, uint256 amount ) public payable {
        
        require(AllowListMintOpen, "allow list has been closed");
        require(m_allowList[msg.sender], "you are not registered in the allow list");
        require( msg.value == allowListMintPrice * amount, "incorrect amount sent");
        require(totalSupply(id) + amount <= maxSupply, "specify a num that makes sense keeping the max supply in mind");  //emphasis on ts(id): from 1155supply, amount should be added to keep it uner max supply. eg max supply is only 20 and we mint amount of 3000. lol         
        require(id <= 3, "id does not exist");
        require(m_maxTokenTypePerWallet[msg.sender][id] + amount < 3, "one address cannot have more than 3 copies");
        _mint(msg.sender, id, amount, "");
    } 

    //2 bool params are used to allow (allow list minting) and (public minting) 
    function PermitForAllowLists( bool approvalBoolPublic, bool approvalBoolAllowList ) external onlyOwner {    //owner allows whether public or alllow minting should be open
        PublicMintOpen = approvalBoolPublic;                 //owner will set 
        AllowListMintOpen = approvalBoolAllowList;
    }

    //addresses should be passsed as: ["0x8s2b27t73", "0x6gftsiasdgiyde"]
    function storeAllowList(address[] calldata allowListAddresses) external onlyOwner {
        
        for (uint256 i = 0 ; i < allowListAddresses.length ; i++ ){
            m_allowList[ allowListAddresses[i] ] = true;
        }
    }
}
