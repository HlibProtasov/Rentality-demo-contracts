const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams } = require('../test/utils')

async function main() {
  // let contract = await ethers.getContractAt('RentalityCarToken','0x3603108a50B6248e433b504436611905f5742356')
  // console.log(await contract.updateGeoServiceAddress('0x09028ca45AF96a117CCa7b60229809aF473Cf964'))
  await upgrades.forceImport('0x4c29f11D5d83F55570DCd38562A0906a5291f5a0',await ethers.getContractFactory('RentalityReferralProgram',{
  libraries:{
    RentalityRefferalLib:'0xe399Bf78E2A31075c9FebFce8b44A48184e79148'
  }
  }))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
