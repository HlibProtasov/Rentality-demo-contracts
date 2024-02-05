const { ethers, network, upgrades } = require('hardhat')
const saveJsonAbi = require('./utils/abiSaver')
const addressSaver = require('./utils/addressSaver')
const { startDeploy } = require('./utils/deployHelper')
const readlineSync = require('readline-sync')

async function main() {
  const { contractName, chainId } = await startDeploy('RentalityGeoService')

  if (chainId < 0) throw new Error('chainId is not set')

  let contract

  if (!readlineSync.keyInYNStrict('Do you want to deploy Mock contract?')) {
    const linkToken = '0x779877A7B0D9E8603169DdbD7836e478b4624789'
    const oracle = '0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD'

    console.log(`Deploying RentalityGeoService for sepolia ...`)
    const contractFactory = await ethers.getContractFactory(contractName)
    contract = await contractFactory.deploy(linkToken, oracle)
  } else {
    const mockContractName = 'RentalityGeoMock'

    console.log(`Deploying geo mock contact...`)
    console.log('WARNING!! Height gas price!! Approximately 0.1 eth')
    const contractFactory = await ethers.getContractFactory(mockContractName)
    contract = await contractFactory.deploy()
  }

  await contract.waitForDeployment()
  const contractAddress = await contract.getAddress()

  console.log(`${contractName} was deployed to: ${contractAddress}`)
  addressSaver(contractAddress, contractName, true, chainId)
  await saveJsonAbi(contractName, chainId, contract)
  console.log()
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
