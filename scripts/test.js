const saveJsonAbi = require('./utils/abiSaver')
const { ethers, upgrades } = require('hardhat')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const { emptyLocationInfo, getEmptySearchCarParams, zeroHash } = require('../test/utils')
const addresses = {
  "RentalityCarToken": "0x3C82AdaCb2081a86EE455dE84887266653FBd70C",
  "RentalityCurrencyConverter": "0x55De68cec6203230c42F0a5D7ae3EdCA931769bB",
  "RentalityTripService": "0xD5980a6DfE414103E717a3c5f61874a366D1C132",
  "RentalityUserService": "0x473827695B86bA1935b800D1C8E843b5373046A3",
  "RentalityPlatform": "0x583Ec73843D491a49AF58DEb49d8E42529591Fb3",
  "RentalityPaymentService": "0x7f479eC672a25645027A1fF855f13d67C48aa0fa",
  "RentalityClaimService": "0x9837f637f222853be215004FdC9540361A84da34",
  "RentalityAdminGateway": "0x7D2085b25a7Cb1737dF8d1d138790b6EAa981899",
  "RentalityCarDelivery": "0x748ed94F997a89Dfa807f50AE8F66dC0f801dB79",
  "RentalityView": "0xB64FD84cae5d47540f732A23d1Ae5084AA9d7af5"
};

const RentalityContract = {
  carService: addresses.RentalityCarToken,
  currencyConverterService: addresses.RentalityCurrencyConverter,
  tripService: addresses.RentalityTripService,
  userService: addresses.RentalityUserService,
  rentalityPlatform: addresses.RentalityPlatform,
  paymentService: addresses.RentalityPaymentService,
  claimService: addresses.RentalityClaimService,
  adminService: addresses.RentalityAdminGateway,
  deliveryService: addresses.RentalityCarDelivery,
  viewService: addresses.RentalityView
};
async function main() {
 

  let contract = await ethers.getContractAt('RentalityCarToken', '0x5a450aB8C86BA17655a1ACf03114bD3EE986DD4e')
  console.log(await contract.getAllCars())

  
  // let contract1 = await ethers.getContractAt('RentalityView', '0xB64FD84cae5d47540f732A23d1Ae5084AA9d7af5')
  // console.log(await contract1.updateServiceAddresses(RentalityContract,'0x1c37e75Aa421578a6D90634ecFd4A958Ad96Ce20','0x99c2435A888a1949E83179ba2b10fA778497E628'))

  // let contract2 = await ethers.getContractAt('RentalityTripsView', '0x99c2435A888a1949E83179ba2b10fA778497E628')
  // console.log(await contract2.updateServiceAddresses(RentalityContract,'0x1c37e75Aa421578a6D90634ecFd4A958Ad96Ce20'))
 

  //  let contract3 = await ethers.getContractAt('RentalityPlatform', '0x583Ec73843D491a49AF58DEb49d8E42529591Fb3')
  // console.log(await contract3.updateServiceAddresses('0x7D2085b25a7Cb1737dF8d1d138790b6EAa981899'))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
