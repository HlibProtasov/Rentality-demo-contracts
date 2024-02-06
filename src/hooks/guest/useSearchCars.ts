import { useCallback, useState } from "react";
import { getEtherContract } from "../../abis";
import {
  ContractAvailableCarInfo,
  ENGINE_TYPE_ELECTRIC_STRING,
  ENGINE_TYPE_PATROL_STRING,
  getEngineTypeString,
  validateContractAvailableCarInfo,
} from "@/model/blockchain/ContractCarInfo";
import { calculateDays } from "@/utils/date";
import { getIpfsURIfromPinata, getMetaDataFromIpfs } from "@/utils/ipfsUtils";
import { ContractCreateTripRequest } from "@/model/blockchain/ContractCreateTripRequest";
import { SearchCarInfo, SearchCarsResult, emptySearchCarsResult } from "@/model/SearchCarsResult";
import { SearchCarRequest } from "@/model/SearchCarRequest";
import { ContractSearchCarParams } from "@/model/blockchain/ContractSearchCarParams";
import { useRentality } from "@/contexts/rentalityContext";
import { getBlockchainTimeFromDate, getMoneyInCentsFromString } from "@/utils/formInput";

export const sortOptions = {
  priceAsc: "Price: low to high",
  priceDesc: "Price: high to low",
  distance: "Distance",
};
export type SortOptionKey = keyof typeof sortOptions;
export function isSortOptionKey(key: string): key is SortOptionKey {
  return sortOptions.hasOwnProperty(key);
}

const useSearchCars = () => {
  const rentalityInfo = useRentality();
  const [isLoading, setIsLoading] = useState<Boolean>(false);
  const [searchResult, setSearchResult] = useState<SearchCarsResult>(emptySearchCarsResult);

  const formatSearchAvailableCarsContractRequest = (searchCarRequest: SearchCarRequest) => {
    const startDateTime = new Date(searchCarRequest.dateFrom);
    const endDateTime = new Date(searchCarRequest.dateTo);
    const tripDays = calculateDays(startDateTime, endDateTime);

    const contractDateFrom = getBlockchainTimeFromDate(startDateTime);
    const contractDateTo = getBlockchainTimeFromDate(endDateTime);
    const contractSearchCarParams: ContractSearchCarParams = {
      country: searchCarRequest.country ?? "",
      state: searchCarRequest.state ?? "",
      city: searchCarRequest.city ?? "",
      brand: searchCarRequest.brand ?? "",
      model: searchCarRequest.model ?? "",
      yearOfProductionFrom: BigInt(searchCarRequest.yearOfProductionFrom ?? "0"),
      yearOfProductionTo: BigInt(searchCarRequest.yearOfProductionTo ?? "0"),
      pricePerDayInUsdCentsFrom: BigInt(getMoneyInCentsFromString(searchCarRequest.pricePerDayInUsdFrom)),
      pricePerDayInUsdCentsTo: BigInt(getMoneyInCentsFromString(searchCarRequest.pricePerDayInUsdTo)),
    };
    return [contractDateFrom, contractDateTo, contractSearchCarParams, tripDays] as const;
  };

  const formatSearchAvailableCarsContractResponse = async (
    availableCarsView: ContractAvailableCarInfo[],
    tripDays: number
  ) => {
    if (availableCarsView.length === 0) return [];

    if (rentalityInfo == null) {
      console.error("formatSearchAvailableCarsContractResponse error: rentalityInfo is null");
      return [];
    }

    return await Promise.all(
      availableCarsView.map(async (i: ContractAvailableCarInfo, index) => {
        if (index === 0) {
          validateContractAvailableCarInfo(i);
        }
        const tokenURI = await rentalityInfo.rentalityContract.getCarMetadataURI(i.car.carId);
        const meta = await getMetaDataFromIpfs(tokenURI);

        const pricePerDay = Number(i.car.pricePerDayInUsdCents) / 100;
        const totalPrice = pricePerDay * tripDays;
        const securityDeposit = Number(i.car.securityDepositPerTripInUsdCents) / 100;
        const engineTypeString = getEngineTypeString(i.car.engineType);
        const fuelPrices =
          engineTypeString === ENGINE_TYPE_PATROL_STRING
            ? [Number(i.car.engineParams[1])]
            : engineTypeString === ENGINE_TYPE_ELECTRIC_STRING
            ? [
                Number(i.car.engineParams[0]),
                Number(i.car.engineParams[1]),
                Number(i.car.engineParams[2]),
                Number(i.car.engineParams[3]),
              ]
            : [];

        let item: SearchCarInfo = {
          carId: Number(i.car.carId),
          ownerAddress: i.car.createdBy.toString(),
          image: getIpfsURIfromPinata(meta.image),
          brand: meta.attributes?.find((x: any) => x.trait_type === "Brand")?.value ?? "",
          model: meta.attributes?.find((x: any) => x.trait_type === "Model")?.value ?? "",
          year: meta.attributes?.find((x: any) => x.trait_type === "Release year")?.value ?? "",
          licensePlate: meta.attributes?.find((x: any) => x.trait_type === "License plate")?.value ?? "",
          seatsNumber: meta.attributes?.find((x: any) => x.trait_type === "Seats number")?.value ?? "",
          transmission: meta.attributes?.find((x: any) => x.trait_type === "Transmission")?.value ?? "",
          engineType: getEngineTypeString(i.car.engineType),
          milesIncludedPerDay: i.car.milesIncludedPerDay.toString(),
          pricePerDay: pricePerDay,
          days: tripDays,
          totalPrice: totalPrice,
          securityDeposit: securityDeposit,
          hostPhotoUrl: i.hostPhotoUrl,
          hostName: i.hostName,
          fuelPrices: fuelPrices,
        };
        return item;
      })
    );
  };

  const searchAvailableCars = async (searchCarRequest: SearchCarRequest) => {
    if (rentalityInfo === null) {
      console.error("searchAvailableCars: rentalityInfo is null");
      return false;
    }
    const rentalityContract = rentalityInfo.rentalityContract;

    try {
      setIsLoading(true);

      const [contractDateFrom, contractDateTo, contractSearchCarParams, tripDays] =
        formatSearchAvailableCarsContractRequest(searchCarRequest);

      const availableCarsView: ContractAvailableCarInfo[] = await rentalityContract.searchAvailableCars(
        contractDateFrom,
        contractDateTo,
        contractSearchCarParams
      );

      const availableCarsData = await formatSearchAvailableCarsContractResponse(availableCarsView, tripDays);

      setSearchResult({
        searchCarRequest: searchCarRequest,
        carInfos: availableCarsData,
      });
      return true;
    } catch (e) {
      console.error("updateData error:" + e);
      return false;
    } finally {
      setIsLoading(false);
    }
  };

  const createTripRequest = async (
    carId: number,
    host: string,
    startDateTime: Date,
    endDateTime: Date,
    startLocation: string,
    endLocation: string,
    totalDayPriceInUsdCents: number,
    taxPriceInUsdCents: number,
    depositInUsdCents: number,
    fuelPrices: number[]
  ) => {
    if (rentalityInfo === null) {
      console.error("createTripRequest: rentalityInfo is null");
      return false;
    }

    try {
      const rentalityContract = rentalityInfo.rentalityContract;
      const rentalityCurrencyConverterContract = await getEtherContract("currencyConverter");
      if (rentalityContract == null) {
        console.error("createTripRequest error: rentalityContract is null");
        return false;
      }
      if (rentalityCurrencyConverterContract == null) {
        console.error("createTripRequest error: rentalityCurrencyConverterContract is null");
        return false;
      }
      const startTime = getBlockchainTimeFromDate(startDateTime);
      const endTime = getBlockchainTimeFromDate(endDateTime);

      const rentPriceInUsdCents = (totalDayPriceInUsdCents + taxPriceInUsdCents + depositInUsdCents) | 0;
      const [rentPriceInEth, ethToCurrencyRate, ethToCurrencyDecimals] =
        await rentalityCurrencyConverterContract.getEthFromUsdLatest(rentPriceInUsdCents);

      const tripRequest: ContractCreateTripRequest = {
        carId: BigInt(carId),
        host: host,
        startDateTime: startTime,
        endDateTime: endTime,
        startLocation: startLocation,
        endLocation: endLocation,
        totalDayPriceInUsdCents: totalDayPriceInUsdCents,
        taxPriceInUsdCents: taxPriceInUsdCents,
        depositInUsdCents: depositInUsdCents,
        fuelPrices: fuelPrices.map((i) => BigInt(i)),
        ethToCurrencyRate: BigInt(ethToCurrencyRate),
        ethToCurrencyDecimals: Number(ethToCurrencyDecimals),
      };

      let transaction = await rentalityContract.createTripRequest(tripRequest, {
        value: rentPriceInEth,
      });
      await transaction.wait();
      return true;
    } catch (e) {
      console.error("createTripRequest error:" + e);
      return false;
    }
  };

  function sortByDailyPriceAsc(a: SearchCarInfo, b: SearchCarInfo) {
    return a.pricePerDay - b.pricePerDay;
  }
  function sortByDailyPriceDes(a: SearchCarInfo, b: SearchCarInfo) {
    return b.pricePerDay - a.pricePerDay;
  }

  function sortByIncludedDistance(a: SearchCarInfo, b: SearchCarInfo) {
    return Number(a.milesIncludedPerDay) - Number(b.milesIncludedPerDay);
  }

  const sortSearchResult = useCallback((sortBy: SortOptionKey) => {
    const sortLogic =
      sortBy === "distance"
        ? sortByIncludedDistance
        : sortBy === "priceDesc"
        ? sortByDailyPriceDes
        : sortByDailyPriceAsc;

    setSearchResult((current) => {
      return {
        searchCarRequest: current.searchCarRequest,
        //TODO carInfos: current.carInfos.toSorted(sortLogic),
        carInfos: [...current.carInfos].sort(sortLogic),
      };
    });
  }, []);
  return [isLoading, searchAvailableCars, searchResult, sortSearchResult, createTripRequest] as const;
};

export default useSearchCars;
