// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IKetherHomepage {

  struct Ad {
    address owner;
    uint x;
    uint y;
    uint width;
    uint height;
    string link;
    string image;
    string title;
    bool NSFW;
    bool forceNSFW;
  }

  function ads(uint _idx) external returns(Ad memory);
  function setAdOwner(uint _idx, address _newOwner) external;
  function publish(uint _idx, string memory _link, string memory _image, string memory _title, bool _NSFW) external;
  
}
