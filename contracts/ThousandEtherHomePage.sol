// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import './IKetherHomepage.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';

contract ThousandEtherHomePage is ERC721, ReentrancyGuard, Ownable {
  
  using Strings for uint256;
  using SafeMath for uint256;

  // Original Contract
  IKetherHomepage public originalContract;

  // Owners pre wrap
  mapping (uint256 => address) public preWrapOwners;

  // Meta data
  mapping (uint256 => uint256[]) public metaData;

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
    (address adOwner,uint x, uint y, uint width, uint height,,,,,) = _ad(adId);
    require(adOwner != address(0), 'Please call preWrap first!');
    require(preWrapOwners[adId] == msg.sender, 'Only the original owner can wrap an Ad!');
    require(adOwner == address(this), 'Please setAdOwner to the wrapper contract!');
    _safeMint(preWrapOwners[adId], adId);
    preWrapOwners[adId] = address(0);
    metaData[adId] = [x, y, width, height];
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

  // Token Metadata
  function tokenURI(uint256 adId) override public view returns (string memory) {
    // string memory name = generateName(adId);
    // string memory image = Base64.encode(bytes(generateSVGImage(params)));
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                generateName(adId),
                '", "image": "',
                'data:image/svg+xml;base64,',
                generateImage(adId),
                '", "attributes": [',
                generateAttributes(adId),
                ']}'
              )
            )
          )
        )
      );
  }

  function generateName(uint256 adId) private view returns (string memory) {
    return string(
      abi.encodePacked(
        'Advertisement ',
        (metaData[adId][2]*10).toString(),
        'x',
        (metaData[adId][3]*10).toString(),
        ' pixels at position ',
        (metaData[adId][0]*10).toString(),
        ',',
        (metaData[adId][1]*10).toString()
      )
    );
  }

  function generateImage(uint256 adId) private view returns (string memory) {
    return Base64.encode(bytes(
      string(
        abi.encodePacked(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 1200"><defs><style>.cls-1{fill:#fff;}.cls-2{fill:#f9f9f9;}.cls-3{fill:#f068a2;}</style></defs><rect class="cls-1" width="1200" height="1200"/><rect class="cls-2" x="100" y="100" width="1000" height="1000"/>',
          '<rect class="cls-3" x="',
          ((metaData[adId][0]*10)+100).toString(),
          '" y="',
          ((metaData[adId][1]*10)+100).toString(),
          '" width="',
          (metaData[adId][2]*10).toString(),
          '" height="',
          (metaData[adId][3]*10).toString(),
          '"/>',
          '</svg>'
        )
      )
    ));
  }

  function generateAttributes(uint256 adId) private view returns (string memory) {
    return
      string(
        abi.encodePacked(
          '{',
          '"trait_type": "WIDTH", ',
          '"value": ',
          (metaData[adId][2]*10).toString(),
          '},',
          '{',
          '"trait_type": "HEIGHT", ',
          '"value": ',
          (metaData[adId][3]*10).toString(),
          '},',
          '{',
          '"trait_type": "X", ',
          '"value": ',
          (metaData[adId][0]*10).toString(),
          '},',
          '{',
          '"trait_type": "Y", ',
          '"value": ',
          (metaData[adId][1]*10).toString(),
          '}'
        )
      );
  }
}
