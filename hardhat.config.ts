import '@nomiclabs/hardhat-waffle'
import 'hardhat-typechain'
import 'solidity-coverage'
import { HardhatUserConfig } from 'hardhat/types'

export default {
  solidity: {
    compilers: ['0.4.15', '0.8.6'].map((version)=>{
      return({
        version,
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      })
    })
  }
}
