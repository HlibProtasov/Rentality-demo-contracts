const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')
const { expect } = require('chai')
const { getMockCarRequest, zeroHash } = require('../utils')
const { getEmptySearchCarParams, emptyLocationInfo } = require('../utils')
const { deployDefaultFixture } = require('./deployments')
describe('Rentality: cars', function () {
  it('Host can add car to rentality', async function () {
    const { rentalityCarToken, rentalityView, rentalityPlatform, host, admin, rentalityLocationVerifier } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityPlatform
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
  })
  it('Host dont see own cars as available', async function () {
    const { rentalityPlatform, rentalityCarToken, host, rentalityLocationVerifier, admin } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityPlatform
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityCarToken.connect(host).getAvailableCarsForUser(host.address)
    expect(availableCars.length).to.equal(0)
  })
  it('Guest see cars as available', async function () {
    const { rentalityCarToken,rentalityPlatform, host,rentalityView, guest, rentalityLocationVerifier, admin, rentalityGateway } =
      await loadFixture(deployDefaultFixture)

    await expect(
      rentalityPlatform
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityCarToken.connect(host).getCarsOwnedByUser(host.address)
    expect(myCars.length).to.equal(1)
    const availableCars = await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(
        0,
        new Date().getSeconds() + 86400,
        getEmptySearchCarParams(1),
        emptyLocationInfo,
        emptyLocationInfo
      )
    expect(availableCars.length).to.equal(1)
  })
})
