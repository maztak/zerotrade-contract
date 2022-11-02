// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract ZeroTrade is ReentrancyGuard, ERC721Holder {
  using Counters for Counters.Counter;
  Counters.Counter public _itemCount; // TODO: change to private if neeeded
  Counters.Counter public _listedItemCount; // TODO: change to private if needed

  mapping(address => mapping(uint256 => Item)) public _nftToItem; // TODO: change to private if needed  

  mapping(uint256 => address) public _itemToContract;
  mapping(address => uint256[]) public _contractToTokenIds;
  mapping(address => uint256) public _contractTokenCount;

  struct Item {
    address nftContract;
    uint256 tokenId;
    address seller;
    address owner;
    address specifiedBuyer;
    uint256 price;
    bool listed;
  }

  event NFTListed(
    address nftContract,
    uint256 tokenId,
    address seller,
    address owner,
    address specifiedBuyer,
    uint256 price
  );

  event NFTCancelListing(
    address nftContract,
    uint256 tokenId,
    address canceler,
    address owner
  );

  event NFTSold(
    address nftContract,
    uint256 tokenId,
    address seller,
    address buyer,
    uint256 price
  );

  constructor() {
    
  }

  function list(address _nftContract, uint256 _tokenId, address _buyer, uint256 _price) public payable nonReentrant { // TODO: Rename to escraw
    require(_price > 0, "Price must be at least 1 wei");
    require(_nftToItem[_nftContract][_tokenId].nftContract == address(0x0), "This NFT has been listed in the past. Use reList function.");
    
    IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

    _nftToItem[_nftContract][_tokenId] = Item(
      _nftContract,
      _tokenId, 
      payable(msg.sender),
      payable(address(this)),
      _buyer,
      _price,
      true
    );
    uint256 itemCount = _itemCount.current();
    _itemCount.increment();
    _listedItemCount.increment();

    _itemToContract[itemCount] = _nftContract;
    _contractToTokenIds[_nftContract].push(_tokenId);
    _contractTokenCount[_nftContract]++;
    emit NFTListed(_nftContract, _tokenId, msg.sender, address(this), _buyer, _price);
  }

  function reList(address _nftContract, uint256 _tokenId, address _buyer, uint256 _price) public payable nonReentrant {
    require(_price > 0, "Price must be at least 1 wei");
    require(_nftToItem[_nftContract][_tokenId].nftContract == address(0x0), "This NFT is listed first time. Use list function.");

    IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);

    _nftToItem[_nftContract][_tokenId] = Item(
      _nftContract,
      _tokenId,
      payable(msg.sender),
      payable(address(this)),
      _buyer,
      _price,
      true
    );

    _listedItemCount.increment();
    emit NFTListed(_nftContract, _tokenId, msg.sender, address(this), _buyer, _price);
  }

  function cancelListing(address _nftContract, uint256 _tokenId) public payable nonReentrant { // TODO: Rename to withdraw
    Item memory item = _nftToItem[_nftContract][_tokenId];
    require(msg.sender == item.seller, "You are not the seller");

    address payable canceler = payable(msg.sender);
    IERC721(_nftContract).safeTransferFrom(address(this), canceler, _tokenId);

    _nftToItem[_nftContract][_tokenId] = Item(
      _nftContract,
      _tokenId,
      address(0),
      canceler,
      address(0),
      0,
      false
    );

    _listedItemCount.decrement();
    emit NFTCancelListing(_nftContract, item.tokenId, msg.sender, item.owner);
  }

  function buy(address _nftContract, uint256 _tokenId) public payable nonReentrant {
    Item memory item = _nftToItem[_nftContract][_tokenId];
    require(msg.value >= item.price, "Not enough ether to cover asking price");
    require(msg.sender == item.specifiedBuyer, "You are not specified buyer");

    address payable buyer = payable(msg.sender);
    payable(item.seller).transfer(msg.value);
    IERC721(_nftContract).safeTransferFrom(address(this), buyer, _tokenId);

    _nftToItem[_nftContract][_tokenId] = Item(
      _nftContract,
      _tokenId,
      address(0),
      buyer,
      address(0),
      0,
      false
    );

    _listedItemCount.decrement();
    emit NFTSold(_nftContract, item.tokenId, item.seller, buyer, msg.value);
  }

  function getListedItems() public view returns (Item[] memory) {
    uint256 itemCount = _itemCount.current();
    uint256 listedItemCount = _listedItemCount.current();

    Item[] memory items = new Item[](listedItemCount);
    uint itemsIndex = 0;
    for (uint i = 0; i < itemCount; i++) {
      address nftContract = _itemToContract[i];
      uint256 contractTokenCount = _contractTokenCount[nftContract];
      uint256[] memory tokenIds = new uint256[](contractTokenCount);
      tokenIds = _contractToTokenIds[nftContract];
   
      for (uint j = 0; j < contractTokenCount; j++) {
        uint256 tokenId = tokenIds[j];
        if (_nftToItem[nftContract][tokenId].listed) {
          items[itemsIndex] = _nftToItem[nftContract][tokenId];
          itemsIndex++;
        }
      }
    }
    return items;
  }

  function getMyListedItems() public view returns (Item[] memory) {
    uint256 itemCount = _itemCount.current();
    uint256 listedItemCount = _listedItemCount.current();

    Item[] memory items = new Item[](listedItemCount);
    uint itemsIndex = 0;
    for (uint i = 0; i < itemCount; i++) {
      address nftContract = _itemToContract[i];
      uint256 contractTokenCount = _contractTokenCount[nftContract];
      uint256[] memory tokenIds = new uint256[](contractTokenCount);
      tokenIds = _contractToTokenIds[nftContract];
   
      for (uint j = 0; j < contractTokenCount; j++) {
        uint256 tokenId = tokenIds[j];
        if (_nftToItem[nftContract][tokenId].listed && _nftToItem[nftContract][tokenId].seller == msg.sender) {
          items[itemsIndex] = _nftToItem[nftContract][tokenId];
          itemsIndex++;
        }
      }
    }
    return items;
  }
}
