const { ethers, upgrades } = require('hardhat')
const { startRecovering } = require('./common')
const { readFromFile, getContractAddress } = require('../utils/contractAddress')
const { checkNotNull } = require('../utils/deployHelper')

async function main() {
  let [contractName, chainId] = await startRecovering()

  const rentalityUtilsAddress = checkNotNull(
    getContractAddress('RentalityUtils', 'scripts/deploy_1a_RentalityUtils.js', chainId),
    'RentalityUtils'
  )

  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      RentalityUtils: rentalityUtilsAddress,
    },
  })

  const proxyAddress = checkNotNull(readFromFile(contractName, chainId), contractName)

  const _ = await upgrades.forceImport(proxyAddress, contractFactory)

  console.log('Proxy files successfully recovered!')
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
