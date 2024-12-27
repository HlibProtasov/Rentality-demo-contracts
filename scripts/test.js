const saveJsonAbi = require('./utils/abiSaver')
const { ethers } = require('hardhat')

async function main() {

    // 1 true
    // 2 false false true
    // const view = await ethers.getContractAt('RentalityTripService','0xDB00B0aaD3D43590232280d056DCA49d017A10c2')
    // console.log(await view.getTrip(180))
  const view = await ethers.getContractAt('RentalityView','0x2DDa5aCFA3d4FB2bb71143c7FA3DbaF194d69545')
  const result = await view.getInsurancesBy(false,'0x2729226a14B02D5726821d5a83d7563aCD6D3760')
  console.log(result.filter(i => i.tripId === BigInt(180) && i.isActual ))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
