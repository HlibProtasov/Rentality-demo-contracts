import { getIpfsURIfromPinata, getMetaDataFromIpfs, parseMetaData } from "@/utils/ipfsUtils";
import { ContractCarDetails, ContractCarInfo } from "../blockchain/schemas";
import { getMilesIncludedPerDayText, HostCarInfo } from "../HostCarInfo";
import { ENGINE_TYPE_ELECTRIC_STRING, ENGINE_TYPE_PETROL_STRING, getEngineTypeString } from "../EngineType";
import { displayMoneyFromCentsWith2Digits } from "@/utils/numericFormatters";

export const mapContractCarToCarDetails = async (
  carInfo: ContractCarInfo,
  carInfoDetails: ContractCarDetails,
  tokenURI: string
): Promise<HostCarInfo> => {
  const metaData = parseMetaData(await getMetaDataFromIpfs(tokenURI));

  const price = Number(carInfo.pricePerDayInUsdCents) / 100;
  const securityDeposit = Number(carInfo.securityDepositPerTripInUsdCents) / 100;
  const engineTypeString = getEngineTypeString(carInfo.engineType);

  const fuelPricePerGal =
    engineTypeString === ENGINE_TYPE_PETROL_STRING ? displayMoneyFromCentsWith2Digits(carInfo.engineParams[1]) : "";
  const fullBatteryChargePrice =
    engineTypeString === ENGINE_TYPE_ELECTRIC_STRING ? displayMoneyFromCentsWith2Digits(carInfo.engineParams[0]) : "";

  return {
    carId: Number(carInfo.carId),
    ownerAddress: carInfo.createdBy.toString(),
    image: getIpfsURIfromPinata(metaData.image),
    vinNumber: carInfo.carVinNumber,
    brand: carInfo.brand,
    model: carInfo.model,
    releaseYear: Number(carInfo.yearOfProduction).toString(),
    name: metaData.name,
    licensePlate: metaData.licensePlate,
    licenseState: metaData.licenseState,
    seatsNumber: metaData.seatsNumber,
    doorsNumber: metaData.doorsNumber,
    tankVolumeInGal: metaData.tankVolumeInGal,
    wheelDrive: metaData.wheelDrive,
    transmission: metaData.transmission,
    trunkSize: metaData.trunkSize,
    color: metaData.color,
    bodyType: metaData.bodyType,
    description: metaData.description,
    pricePerDay: price.toString(),
    milesIncludedPerDay: getMilesIncludedPerDayText(carInfo.milesIncludedPerDay),
    securityDeposit: securityDeposit.toString(),
    locationInfo: {
      address: carInfoDetails.locationInfo.userAddress
        .split(",")
        .map((i) => i.trim())
        .join(", "),
      country: carInfoDetails.locationInfo.country,
      state: carInfoDetails.locationInfo.state,
      city: carInfoDetails.locationInfo.city,
      latitude: Number(carInfoDetails.locationInfo.latitude),
      longitude: Number(carInfoDetails.locationInfo.longitude),
      timeZoneId: carInfoDetails.locationInfo.timeZoneId,
    },
    isLocationEdited: false,
    currentlyListed: carInfo.currentlyListed,
    engineTypeText: engineTypeString,
    fuelPricePerGal: fuelPricePerGal,
    fullBatteryChargePrice: fullBatteryChargePrice,
    timeBufferBetweenTripsInMin: Number(carInfo.timeBufferBetweenTripsInSec) / 60,
    isInsuranceIncluded: carInfo.insuranceIncluded,
  };
};
