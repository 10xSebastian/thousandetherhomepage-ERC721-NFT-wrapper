import { ethers } from 'hardhat'

export default async (contractOwner, withdrawWallet) => {
  const Original = await ethers.getContractFactory('KetherHomepage')
  const original = await Original.deploy(contractOwner.address, withdrawWallet.address)
  await original.deployed()

  return original
}
