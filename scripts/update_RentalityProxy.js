const { ethers, upgrades, network } = require('hardhat')
const { readFromFile, getContractAddress } = require('./utils/contractAddress')
const readlineSync = require('readline-sync')
const saveJsonAbi = require('./utils/abiSaver')
const { checkNotNull } = require('./utils/deployHelper')
async function main() {
  const [deployer] = await ethers.getSigners()

  const balance = await ethers.provider.getBalance(deployer.address)
  console.log('Deployer address is:', await deployer.getAddress(), ' with balance:', balance)

  const chainId = (await deployer.provider?.getNetwork())?.chainId ?? -1
  const contractName = readlineSync.question('Enter contract name to update:\n')

  const rentalityUtilsAddress = checkNotNull(
    getContractAddress('RentalityUtils', 'scripts/deploy_1a_RentalityUtils.js', chainId),
    'RentalityUtils'
  )
  const rentalityQueryAddress = checkNotNull(
    getContractAddress('RentalityQuery', 'scripts/deploy_1d_RentalityQuery.js', chainId),
    'RentalityQuery'
  )

  console.log('Contract name: ', contractName)

  const contractAddress = readFromFile(contractName, chainId)

  if (contractAddress === null) {
    console.log(`Contract address ${contractName}: not found. Finishing... `)
    process.exit(1)
  }
  const contractFactory = await ethers.getContractFactory(contractName, {
    libraries: {
      RentalityQuery: rentalityQueryAddress,
      RentalityUtils: rentalityUtilsAddress,
    },
  })

  const initializationFunc = readlineSync.question("Enter initialization function if needed or 'Enter' to skip:\n")

  let contract
  if (initializationFunc.length === 0) {
    console.log(`Updating contract ${contractName} in address ${contractAddress}`)
    contract = await upgrades.upgradeProxy(contractAddress, contractFactory)
  } else {
    const initializationArgs = readlineSync.question(
      `Enter args to ${initializationFunc} function arguments separated by spaces or skip \n`
    )

    const args = initializationArgs.split(/\s+/)

    console.log(
      `Updating contract ${contractName} in address ${contractAddress} with function ${initializationFunc} with args \n ${args}`
    )
    contract = await upgrades.upgradeProxy(contractAddress, contractFactory, {
      call: {
        fn: initializationFunc,
        args: args,
      },
    })
  }

  await saveJsonAbi(contractName, chainId, contract)
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
