const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')

async function main() {

  // await upgrades.forceImport('0xe5415e8eb93bd3e6c052f6b815fcfbb74231b3e4', await ethers.getContractFactory('RentalityPlatform',{
  //   libraries: {
  //     RentalityQuery: '0x45C184a5aBfbcea133c66090617DDED25e48bF63',
  //     RentalityUtils: '0x218a24741B68981F778E52e9A6435dCC8B6533F7'
  //   }
  // }))
  let contract = await ethers.getContractAt('RentalityAdminGateway','0xCB3A446A43F14dbd1484F7a73E46eDCe132D44A5' )
  // console.log(await contract.getRentalityContracts())
  console.log(await contract.updateRefferalProgramService('0x32db650576Bbed5d65C729fB82115766E48c036E'))

let platform = await ethers.getContractAt('RentalityPlatform','0xe5415e8eb93bd3e6c052f6b815fcfbb74231b3e4')
console.log(await platform.updateServiceAddresses('0xCB3A446A43F14dbd1484F7a73E46eDCe132D44A5'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
