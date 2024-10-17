const { expect } = require('chai')
const { loadFixture } = require('@nomicfoundation/hardhat-network-helpers')

const {
  getMockCarRequest,

  deployDefaultFixture,
  getEmptySearchCarParams,
  ethToken,
  calculatePayments,
  signTCMessage,
  zeroHash,
  emptyKyc,
  signKycInfo,
  emptyLocationInfo,
  UserRole,
  emptySignedLocationInfo,
} = require('../utils')

describe('RentalityGateway: user info', function () {
  let rentalityGateway,
    rentalityUserService,
    owner,
    admin,
    manager,
    host,
    guest,
    anonymous,
    rentalityLocationVerifier,
    adminKyc,
    rentalityView,
    rentalityPlatform

  beforeEach(async function () {
    ;({
      rentalityGateway,
      rentalityMockPriceFeed,
      rentalityUserService,
      rentalityTripService,
      rentalityCurrencyConverter,
      rentalityCarToken,
      rentalityPaymentService,
      rentalityGeoService,
      rentalityAdminGateway,
      utils,
      claimService,
      owner,
      admin,
      manager,
      host,
      guest,
      anonymous,
      rentalityLocationVerifier,
      adminKyc,
      rentalityView,
      rentalityPlatform
    } = await loadFixture(deployDefaultFixture))
  })

  it('Should host be able to create KYC', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)

    let kyc = {
      fullName: surname,
      licenseNumber: licenseNumber,
      expirationDate: expirationDate,
      issueCountry: '',
      email: '',
    }
    const adminSignature = signKycInfo(await rentalityLocationVerifier.getAddress(), admin, zeroHash, kyc)

    await expect(rentalityPlatform
        .connect(host)
        .setKYCInfo(name, number, photo, hostSignature, zeroHash)).not.be
      .reverted

    const fullKycInfo = await rentalityView.connect(host).getMyFullKYCInfo()
    let kycInfo = fullKycInfo.kyc
    expect(kycInfo.name).to.equal(name)

    expect(kycInfo.mobilePhoneNumber).to.equal(number)
    expect(kycInfo.profilePhoto).to.equal(photo)
  })
  it('Should guest be able to create KYC', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const guestSignature = await signTCMessage(guest)
    let kyc = {
      fullName: surname,
      licenseNumber: licenseNumber,
      expirationDate: expirationDate,
      issueCountry: '',
      email: '',
    }
    const adminSignature = signKycInfo(await rentalityLocationVerifier.getAddress(), admin, zeroHash, kyc)
    await expect(rentalityPlatform.connect(guest).setKYCInfo(name, number, photo, guestSignature, zeroHash)).not.be
      .reverted

    const fullKycInfo = await rentalityView.connect(guest).getMyFullKYCInfo()
    let kycInfo = fullKycInfo.kyc
    expect(kycInfo.name).to.equal(name)

    expect(kycInfo.mobilePhoneNumber).to.equal(number)
    expect(kycInfo.profilePhoto).to.equal(photo)
  })

  it('Guest should be able to get trip contacts', async function () {
    await expect(
      rentalityPlatform
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
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

    const dailyPriceInUsdCents = 1000

    const result = await rentalityView
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)

    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(rentalityPlatform.connect(guest).setKYCInfo('name', guestNumber, 'photo', guestSignature, zeroHash)).not
      .be.reverted

    await expect(rentalityPlatform
        .connect(host)
        .addCar("name",hostNumber,"",hostSignature, zeroHash)).not.be
      .reverted

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityGateway.connect(guest).getTripContactInfo(1)

    expect(guestPhoneNumber).to.be.equal(guestNumber)
    expect(hostPhoneNumber).to.be.equal(hostNumber)
  })

  it('Host should be able to get trip contacts', async function () {
    await expect(
      rentalityPlatform
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
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

    const dailyPriceInUsdCents = 1000

    const result = await rentalityView
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)
    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(rentalityPlatform.connect(guest).setKYCInfo('name', guestNumber, 'photo', guestSignature, zeroHash)).not
      .be.reverted

    await expect(rentalityPlatform
        .connect(host)
        .setKYCInfo("name",hostNumber,"photo", zeroHash)).not.be
      .reverted

    let [guestPhoneNumber, hostPhoneNumber] = await rentalityGateway.connect(host).getTripContactInfo(1)

    expect(guestPhoneNumber).to.be.equal(guestNumber)
    expect(hostPhoneNumber).to.be.equal(hostNumber)
  })

  it('Only host and guest should be able to get trip contacts', async function () {
    await expect(
      rentalityPlatform
        .connect(host)
        .addCar(getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin), zeroHash)
    ).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
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

    const dailyPriceInUsdCents = 1000

    const result = await rentalityView
      .connect(guest)
      .calculatePaymentsWithDelivery(1, 1, ethToken, emptyLocationInfo, emptyLocationInfo)
    await expect(
      await rentalityPlatform.connect(guest).createTripRequestWithDelivery(
        {
          carId: 1,
          startDateTime: 123,
          endDateTime: 321,
          currencyType: ethToken,
          pickUpInfo: emptySignedLocationInfo,
          returnInfo: emptySignedLocationInfo,
        },
        { value: result.totalPrice }
      )
    ).not.to.be.reverted

    const hostSignature = await signTCMessage(host)
    const guestSignature = await signTCMessage(guest)
    let guestNumber = '+380'
    let hostNumber = '+3801'
    await expect(rentalityPlatform.connect(guest).setKYCInfo('name', 'surname', guestNumber, guestSignature, zeroHash))
      .not.be.reverted

    await expect(rentalityPlatform
        .connect(host)
        .setKYCInfo('name',hostNumber,"asd",hostSignature, zeroHash)).not
      .be.reverted

    await expect(rentalityGateway.connect(anonymous).getTripContactInfo(1)).to.be.reverted
  })
  it('Should have host photoUrl and host name in available car response ', async function () {
    let addCarRequest = getMockCarRequest(0, await rentalityLocationVerifier.getAddress(), admin)
    await expect(rentalityPlatform.connect(host).addCar(addCarRequest, zeroHash)).not.to.be.reverted
    const myCars = await rentalityView.connect(host).getMyCars()
    expect(myCars.length).to.equal(1)

    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)

    await expect(
      rentalityPlatform
        .connect(host)
        .setKYCInfo(name,mobilePhoneNumber,photo,hostSignature , zeroHash)
    ).not.be.reverted

    const availableCars = await rentalityView
      .connect(guest)
      .searchAvailableCarsWithDelivery(0, 1, getEmptySearchCarParams(0), emptyLocationInfo, emptyLocationInfo)
    expect(availableCars.length).to.equal(1)
    expect(availableCars[0].car.hostPhotoUrl).to.be.eq(photo + 'host')
    expect(availableCars[0].car.hostName).to.be.eq(name + 'host')
  })

  it('Should KYC manager be able to add user KYC', async function () {
    let name = 'name'
    let surname = 'surname'
    let number = '+380'
    let photo = 'photo'
    let licenseNumber = 'licenseNumber'
    let expirationDate = 10

    const hostSignature = await signTCMessage(host)

    let kyc = {
      fullName: surname,
      licenseNumber: licenseNumber,
      expirationDate: expirationDate,
      issueCountry: 'ISSUE',
      email: 'EMAIL',
    }

    await expect(rentalityPlatform
        .connect(host)
        .setKYCInfo(kyc.nickName, kyc.mobilePhoneNumber, kyc.profilePhoto,hostSignature, zeroHash)).not.be
      .reverted
   
    await expect(rentalityPlatform.connect(anonymous).setCivicKYCInfo(host.address, kyc, zeroHash)).to.be.reverted

    await expect(
      await rentalityUserService.connect(owner).manageRole(UserRole.KYCManager, await anonymous.getAddress(), true)
    ).to.not.reverted

    await expect(rentalityPlatform.connect(anonymous).setCivicKYCInfo(host.address, kyc, zeroHash)).to.not.reverted
    const kycInfo = await rentalityView.connect(host).getMyFullKYCInfo()

    expect(kycInfo.kyc.name).to.equal(name)
    expect(kycInfo.kyc.surname).to.equal(surname)
    expect(kycInfo.kyc.mobilePhoneNumber).to.equal(number)
    expect(kycInfo.kyc.profilePhoto).to.equal(photo)
    expect(kycInfo.kyc.licenseNumber).to.equal(licenseNumber)
    expect(kycInfo.kyc.expirationDate).to.equal(expirationDate)
    expect(kycInfo.additionalKYC.email).to.eq(kyc.email)
    expect(kycInfo.additionalKYC.issueCountry).to.eq(kyc.issueCountry)
  })
})
