import { isEmpty } from "@/utils/string";
import { ENGINE_TYPE_ELECTRIC_STRING, ENGINE_TYPE_PETROL_STRING } from "./EngineType";
import { LocationInfo } from "./LocationInfo";

export const UNLIMITED_MILES_VALUE_TEXT = "Unlimited";
export const UNLIMITED_MILES_VALUE = 999_999_999;

export const isUnlimitedMiles = (value: bigint | number) => {
  return value === 0 || value >= UNLIMITED_MILES_VALUE;
};

export const getMilesIncludedPerDayText = (value: bigint | number) => {
  return isUnlimitedMiles(value) ? UNLIMITED_MILES_VALUE_TEXT : value.toString();
};

export type HostCarInfo = {
  carId: number;
  ownerAddress: string;
  image: string;
  vinNumber: string;
  brand: string;
  model: string;
  releaseYear: string;
  name: string;
  licensePlate: string;
  licenseState: string;
  seatsNumber: string;
  doorsNumber: string;
  transmission: string;
  color: string;
  description: string;
  pricePerDay: string;
  milesIncludedPerDay: string;
  securityDeposit: string;
  timeBufferBetweenTripsInMin: number;
  currentlyListed: boolean;

  isLocationEdited: boolean;
  locationInfo: LocationInfo;

  engineTypeText: string;

  fuelPricePerGal: string;
  tankVolumeInGal: string;

  fullBatteryChargePrice: string;

  wheelDrive: string;
  bodyType: string;
  trunkSize: string;
  isInsuranceIncluded: boolean;
};

export const verifyCar = (carInfoFormParams: HostCarInfo) => {
  return (
    !isEmpty(carInfoFormParams.vinNumber) &&
    !isEmpty(carInfoFormParams.brand) &&
    !isEmpty(carInfoFormParams.model) &&
    !isEmpty(carInfoFormParams.releaseYear) &&
    !isEmpty(carInfoFormParams.name) &&
    !isEmpty(carInfoFormParams.licensePlate) &&
    !isEmpty(carInfoFormParams.licenseState) &&
    !isEmpty(carInfoFormParams.seatsNumber) &&
    !isEmpty(carInfoFormParams.doorsNumber) &&
    !isEmpty(carInfoFormParams.transmission) &&
    !isEmpty(carInfoFormParams.color) &&
    !isEmpty(carInfoFormParams.description) &&
    !isEmpty(carInfoFormParams.pricePerDay) &&
    !isEmpty(carInfoFormParams.milesIncludedPerDay) &&
    !isEmpty(carInfoFormParams.securityDeposit) &&
    !isEmpty(carInfoFormParams.locationInfo.address) &&
    !isEmpty(carInfoFormParams.engineTypeText) &&
    (carInfoFormParams.engineTypeText !== ENGINE_TYPE_PETROL_STRING || !isEmpty(carInfoFormParams.fuelPricePerGal)) &&
    (carInfoFormParams.engineTypeText !== ENGINE_TYPE_PETROL_STRING || !isEmpty(carInfoFormParams.tankVolumeInGal)) &&
    (carInfoFormParams.engineTypeText !== ENGINE_TYPE_ELECTRIC_STRING ||
      !isEmpty(carInfoFormParams.fullBatteryChargePrice))
  );
};
