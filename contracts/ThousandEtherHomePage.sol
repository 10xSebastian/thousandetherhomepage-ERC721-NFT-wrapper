// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import './IKetherHomepage.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "hardhat/console.sol";

contract ThousandEtherHomePage is ERC721, ReentrancyGuard, Ownable {
  
  using SafeMath for uint256;

  // Original Contract
  IKetherHomepage public originalContract;

  // Owners pre wrap
  mapping (uint256 => address) public preWrapOwners;

  constructor(
    address _originalContractAddress
  ) ERC721("ThousandEtherHomePage", "1000ETH") {
    originalContract = IKetherHomepage(_originalContractAddress);
  }

  // Retrieves ads from the original contract
  function _ad(uint256 id) internal returns(
    address,        // owner
    uint,           // x
    uint,           // y
    uint,           // width
    uint,           // height
    string memory,  // link
    string memory,  // image
    string memory,  // title
    bool,           // NSFW
    bool            // forceNSFW
  ) {
    (bool success, bytes memory returnData) = address(originalContract).call(abi.encodeWithSelector(
        originalContract.ads.selector, id
    ));
    require(success, 'Ad was not retrievable!');
    return abi.decode(returnData, (address, uint, uint, uint, uint, string, string, string, bool, bool));
  }

  // Prepares a wrap (ownership needs to be transfered in a second step)
  function preWrap(uint256 adId) external nonReentrant returns(bool) {
    (address adOwner,,,,,,,,,) = _ad(adId);
    require(adOwner == msg.sender, 'Only the ad owner can preWrap a token!');
    preWrapOwners[adId] = adOwner;
    return true;
  }

  // Allows admin to rescue ownsership if anybody should have forgotten to call preWrap
  // before calling setAdOwner on the orignal contract
  function rescueOwner(uint256 adId, address previousOwner) external onlyOwner returns(bool) {
    require(preWrapOwners[adId] == address(0), 'You can not rescue ownership for a prewrapped token!');
    require(_exists(adId) == false, 'You can not rescue a wrapped/minted token!');
    originalContract.setAdOwner(adId, previousOwner);
    return true;
  }  

  // Wraps a single ad (you can only sell ads not pixels)
  function wrap(uint256 adId) external nonReentrant returns(bool) {
    (address adOwner,,,,,,,,,) = _ad(adId);
    require(adOwner != address(0), 'Please call preWrap first!');
    require(preWrapOwners[adId] == msg.sender, 'Only the original owner can wrap an Ad!');
    require(adOwner == address(this), 'Please setAdOwner to the wrapper contract!');
    _safeMint(preWrapOwners[adId], adId);
    preWrapOwners[adId] = address(0);
    return true;
  }

  // Proxies publish
  function publish(uint _idx, string memory _link, string memory _image, string memory _title, bool _NSFW) external returns(bool) {
    require(ownerOf(_idx) == msg.sender, 'Only the owner of an ad can publish!');
    originalContract.publish(_idx, _link, _image, _title, _NSFW);
    return true;
  }

  // Unwraps a single ad
  function unwrap(uint256 adId) external nonReentrant returns(bool) {
    require(ownerOf(adId) == msg.sender, 'Only the owner can unwrap an Ad!');
    originalContract.setAdOwner(adId, msg.sender);
    _burn(0);
    return true;
  }
}
