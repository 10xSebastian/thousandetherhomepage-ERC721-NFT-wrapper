import deployOriginal from '../test/helpers/deploy/original'
import deployWrapper from '../test/helpers/deploy/wrapper'
import { ethers } from 'hardhat'
import { expect } from 'chai'

describe('ThousandEtherHomePage', function() {

  let wallets,
      originalContract,
      wrapperContract
    
  beforeEach(async ()=>{
    wallets = await ethers.getSigners();
  })

  it('deploys the original contract', async ()=>{
    originalContract = await deployOriginal(wallets[0], wallets[0]);
  })

  it('deploys the NFT wrapper contract', async ()=>{
    wrapperContract = await deployWrapper(originalContract);
  })

  it('requires you to have bought an original ad on thousandetherhomepage in the first place', async ()=>{
    await originalContract.connect(wallets[1]).buy(5, 10, 1, 1, { value: ethers.utils.parseUnits('0.1', 18) });
    await originalContract.connect(wallets[1]).buy(40, 86, 10, 10, { value: ethers.utils.parseUnits('10.0', 18) });
    await originalContract.connect(wallets[1]).buy(20, 21, 10, 1, { value: ethers.utils.parseUnits('1.0', 18) });
    await originalContract.connect(wallets[1]).buy(3, 21, 1, 10, { value: ethers.utils.parseUnits('1.0', 18) });
  })

  it('does not allow others but the owner to preWrap an ad', async()=>{
    await expect(
      wrapperContract.connect(wallets[2]).preWrap(0)
    ).to.be.revertedWith(
      'Only the ad owner can preWrap a token!'
    );
  })

  it('does not allow others but the admin to rescue ownership if someone should have forgotten to call preWrap', async()=>{
    await expect(
      wrapperContract.connect(wallets[3]).rescueOwner(0, wallets[1].address)
    ).to.be.revertedWith(
      'Ownable: caller is not the owner'
    )
  })

  it('allows admin to rescue ownership if someone should have forgotten to call preWrap', async()=>{
    await originalContract.connect(wallets[1]).setAdOwner(0, wrapperContract.address);
    expect((await originalContract.ads(0))[0]).to.eq(wrapperContract.address);
    await expect(
      wrapperContract.connect(wallets[1]).wrap(0)
    ).to.be.revertedWith(
      'Only the original owner can wrap an Ad!'
    )
    await wrapperContract.connect(wallets[0]).rescueOwner(0, wallets[1].address);
    expect((await originalContract.ads(0))[0]).to.eq(wallets[1].address);
  })

  it('fails to mint an NFT if the preWrap owner forgets to change ownership before wrapping', async()=>{
    await wrapperContract.connect(wallets[1]).preWrap(0);
    await expect(
      wrapperContract.connect(wallets[1]).wrap(0)
    ).to.be.revertedWith(
      'Please setAdOwner to the wrapper contract!'
    )
  })

  it('allows the ad owner to preWrap an ad that he owns', async()=>{
    await wrapperContract.connect(wallets[1]).preWrap(0);
    await originalContract.connect(wallets[1]).setAdOwner(0, wrapperContract.address);
  })

  it('does not allow admin to rescue a prewrapped token', async()=>{
    await expect(
      wrapperContract.connect(wallets[0]).rescueOwner(0, wallets[1].address)
    ).to.be.revertedWith(
      'You can not rescue ownership for a prewrapped token!'
    )
  })

  it('does not allow others but the owner to wrap ads', async()=>{
    await expect(
      wrapperContract.connect(wallets[2]).wrap(0)
    ).to.be.revertedWith(
      'Only the original owner can wrap an Ad!'
    )
  })

  it('allows the ad owner to wrap an ad that he owns', async()=>{
    await expect(()=> 
      wrapperContract.connect(wallets[1]).wrap(0)
    ).to.changeTokenBalance(wrapperContract, wallets[1], 1);
    expect(await wrapperContract.ownerOf(0)).to.equal(wallets[1].address);
    expect((await originalContract.ads(0))[0]).to.eq(wrapperContract.address);
    expect(await wrapperContract.preWrapOwners(0)).to.eq('0x0000000000000000000000000000000000000000');
  })

  it('that token stored meta data too', async()=>{
    expect(await wrapperContract.metaData(0, 0)).to.eq(5);
    expect(await wrapperContract.metaData(0, 1)).to.eq(10);
    expect(await wrapperContract.metaData(0, 2)).to.eq(1);
    expect(await wrapperContract.metaData(0, 3)).to.eq(1);
  });

  it('does not allow admin to rescue a wrapped/minted token', async()=>{
    await expect(
      wrapperContract.connect(wallets[0]).rescueOwner(0, wallets[1].address)
    ).to.be.revertedWith(
      'You can not rescue a wrapped/minted token!'
    )
  })

  it('allows the owner of a wrapped token to transfer, sell and list that token', async()=>{
    await expect(()=> 
      wrapperContract.connect(wallets[1])['safeTransferFrom(address,address,uint256)'](wallets[1].address, wallets[5].address, 0)
    ).to.changeTokenBalance(wrapperContract, wallets[5], 1);
  })

  it('allows the new owner to publish an ad', async()=>{
    await wrapperContract.connect(wallets[5]).publish(0, 'https://something.com', 'https://something.com/image.png', 'My Ad', false);
    let ad = await originalContract.ads(0);
    expect(ad[5]).to.equal('https://something.com');
    expect(ad[6]).to.equal('https://something.com/image.png');
    expect(ad[7]).to.equal('My Ad');
    expect(ad[8]).to.equal(false);
  })
  
  it('does not allow the previous owner to publish an ad', async()=>{
    await expect(
      wrapperContract.connect(wallets[1]).publish(0, 'https://something.com', 'https://something.com/image.png', 'My Ad', false)
    ).to.be.revertedWith(
      'Only the owner of an ad can publish!'
    )
  })

  it('does not allow others to unwrap tokens', async()=>{
    await expect(
      wrapperContract.connect(wallets[1]).unwrap(0)
    ).to.be.revertedWith(
      'Only the owner can unwrap an Ad!'
    )
  })

  it('allows an owner to unwrap the token again', async()=>{
    await expect(()=> 
      wrapperContract.connect(wallets[5]).unwrap(0)
    ).to.changeTokenBalance(wrapperContract, wallets[5], -1);
    expect((await originalContract.ads(0))[0]).to.eq(wallets[5].address);
  })
  
  it('allows an owner to wrap the token again also after unwrap', async()=>{
    await wrapperContract.connect(wallets[5]).preWrap(0);
    await originalContract.connect(wallets[5]).setAdOwner(0, wrapperContract.address);
    await expect(()=> 
      wrapperContract.connect(wallets[5]).wrap(0)
    ).to.changeTokenBalance(wrapperContract, wallets[5], 1);
    expect(await wrapperContract.ownerOf(0)).to.equal(wallets[5].address);
    expect((await originalContract.ads(0))[0]).to.eq(wrapperContract.address);
    expect(await wrapperContract.preWrapOwners(0)).to.eq('0x0000000000000000000000000000000000000000');
  })

  it('provides token meta data', async()=>{
    let tokenURI = await wrapperContract.tokenURI(0);
    const json = Buffer.from(tokenURI.split(',')[1], "base64");
    const data = JSON.parse(json.toString());
    expect(data.name).to.eq('Advertisement 10x10 pixels at position 50,100');
    expect(data.image).to.eq('data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMjAwIDEyMDAiPjxkZWZzPjxzdHlsZT4uY2xzLTF7ZmlsbDojZmZmO30uY2xzLTJ7ZmlsbDojZjlmOWY5O30uY2xzLTN7ZmlsbDojZjA2OGEyO308L3N0eWxlPjwvZGVmcz48cmVjdCBjbGFzcz0iY2xzLTEiIHdpZHRoPSIxMjAwIiBoZWlnaHQ9IjEyMDAiLz48cmVjdCBjbGFzcz0iY2xzLTIiIHg9IjEwMCIgeT0iMTAwIiB3aWR0aD0iMTAwMCIgaGVpZ2h0PSIxMDAwIi8+PHJlY3QgY2xhc3M9ImNscy0zIiB4PSIxNTAiIHk9IjIwMCIgd2lkdGg9IjEwIiBoZWlnaHQ9IjEwIi8+PC9zdmc+');
    expect(JSON.stringify(data.attributes)).to.eq(JSON.stringify([
      { trait_type: 'WIDTH', value: 10 },
      { trait_type: 'HEIGHT', value: 10 },
      { trait_type: 'X', value: 50 },
      { trait_type: 'Y', value: 100 }
    ]));
  })
})
