import { ethers } from 'hardhat'

export default async (originalContract) => {
  const Wrapper = await ethers.getContractFactory('ThousandEtherHomePage')
  const wrapper = await Wrapper.deploy(originalContract.address)
  await wrapper.deployed()

  return wrapper
}
