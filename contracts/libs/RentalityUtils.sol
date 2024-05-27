// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '../Schemas.sol';
import '../RentalityUserService.sol';
import '../RentalityCarToken.sol';
import '../abstract/IRentalityGeoService.sol';
import '../RentalityTripService.sol';
import '../payments/RentalityCurrencyConverter.sol';
import '../payments/RentalityPaymentService.sol';
import {RentalityContract} from '../RentalityGateway.sol';
import {RentalityCarDelivery} from '../features/RentalityCarDelivery.sol';
/// @title RentalityUtils Library
/// @notice
/// This library provides utility functions for handling coordinates, string manipulation,
/// and parsing responses related to geolocation data. It includes functions for checking
/// coordinates within a specified bounding box, parsing strings, converting between data types,
/// and URL encoding. The library is used in conjunction with other Rentality contracts.
library RentalityUtils {
  // Constant multiplier for converting decimal coordinates to integers
  uint256 constant multiplier = 10 ** 7;

  /// @notice Checks if a set of coordinates falls within a specified bounding box.
  /// @param locationLat Latitude of the location to check.
  /// @param locationLng Longitude of the location to check.
  /// @param northeastLat Latitude of the northeast corner of the bounding box.
  /// @param northeastLng Longitude of the northeast corner of the bounding box.
  /// @param southwestLat Latitude of the southwest corner of the bounding box.
  /// @param southwestLng Longitude of the southwest corner of the bounding box.
  /// @return Returns true if the coordinates are within the bounding box, false otherwise.
  function checkCoordinates(
    string memory locationLat,
    string memory locationLng,
    string memory northeastLat,
    string memory northeastLng,
    string memory southwestLat,
    string memory southwestLng
  ) external pure returns (bool) {
    int256 lat = parseInt(locationLat);
    int256 lng = parseInt(locationLng);
    int256 neLat = parseInt(northeastLat);
    int256 neLng = parseInt(northeastLng);
    int256 swLat = parseInt(southwestLat);
    int256 swLng = parseInt(southwestLng);

    return (lat >= swLat && lat <= neLat && lng >= swLng && lng <= neLng);
  }

  /// @notice Parses an integer from a string.
  /// @param _a The input string to parse.
  /// @return Returns the parsed integer value.
  function parseInt(string memory _a) internal pure returns (int256) {
    bytes memory bresult = bytes(_a);
    int256 mint = 0;
    bool decimals = false;
    for (uint i = 0; i < bresult.length; i++) {
      if ((uint8(bresult[i]) >= 48) && (uint8(bresult[i]) <= 57)) {
        if (decimals) {
          if (i - 1 - indexOf(bresult, '.') > 6) break;
          mint = mint * 10 + int256(uint256(uint8(bresult[i])) - 48);
        } else {
          mint = mint * 10 + int256(uint256(uint8(bresult[i])) - 48);
        }
      } else if (uint8(bresult[i]) == 46) decimals = true;
    }
    if (indexOf(bresult, '-') == 0) {
      return -mint * int256(multiplier);
    }
    return mint * int256(multiplier);
  }

  /// @notice Finds the index of a substring in a given string.
  /// @param haystack The string to search within.
  /// @param needle The substring to search for.
  /// @return Returns the index of the first occurrence of the substring, or the length of the string if not found.
  function indexOf(bytes memory haystack, string memory needle) internal pure returns (uint) {
    bytes memory bneedle = bytes(needle);
    if (bneedle.length > haystack.length) {
      return haystack.length;
    }

    bool found = false;
    uint i;
    for (i = 0; i <= haystack.length - bneedle.length; i++) {
      found = true;
      for (uint j = 0; j < bneedle.length; j++) {
        if (haystack[i + j] != bneedle[j]) {
          found = false;
          break;
        }
      }
      if (found) {
        break;
      }
    }
    return i;
  }

  /// @notice Converts a string to lowercase.
  /// @param str The input string to convert.
  /// @return Returns the lowercase version of the input string.
  function toLower(string memory str) internal pure returns (string memory) {
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character...
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
        // So we add 32 to make it lowercase
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

  /// @notice Checks if a string contains a specific word.
  /// @param where The string to search within.
  /// @param what The word to search for.
  /// @return found Returns true if the word is found, false otherwise.
  function containWord(string memory where, string memory what) internal pure returns (bool found) {
    bytes memory whatBytes = bytes(what);
    bytes memory whereBytes = bytes(where);

    if (whereBytes.length < whatBytes.length) {
      return false;
    }

    found = false;
    for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
      bool flag = true;
      for (uint j = 0; j < whatBytes.length; j++)
        if (whereBytes[i + j] != whatBytes[j]) {
          flag = false;
          break;
        }
      if (flag) {
        found = true;
        break;
      }
    }
    return found;
  }

  /// @notice Generates a hash from a string.
  /// @param str The input string to hash.
  /// @return Returns the keccak256 hash of the input string.
  function getHashFromString(string memory str) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(str));
  }

  /// @notice Calculates the ceiling of the division of two numbers.
  /// @param startDateTime The numerator of the division.
  /// @param endDateTime The denominator of the division.
  /// @return Returns the result of the division rounded up to the nearest whole number.
  function getCeilDays(uint64 startDateTime, uint64 endDateTime) public pure returns (uint64) {
    uint64 duration = endDateTime - startDateTime;
    return uint64(Math.ceilDiv(duration, 1 days));
  }

  /// @notice Populates an array of chat information using data from trips, user service, and car service.
  /// @return chatInfoList Array of IRentalityGateway.ChatInfo structures.
  function populateChatInfo(
    bool byGuest,
    RentalityContract memory addresses
  ) public view returns (Schemas.ChatInfo[] memory) {
    Schemas.TripDTO[] memory trips = byGuest
      ? getTripsByGuest(addresses, tx.origin)
      : getTripsByHost(addresses, tx.origin);

    RentalityUserService userService = addresses.userService;
    RentalityCarToken carService = addresses.carService;

    Schemas.ChatInfo[] memory chatInfoList = new Schemas.ChatInfo[](trips.length);

    for (uint i = 0; i < trips.length; i++) {
      Schemas.KYCInfo memory guestInfo = userService.getKYCInfo(trips[i].trip.guest);
      Schemas.KYCInfo memory hostInfo = userService.getKYCInfo(trips[i].trip.host);

      chatInfoList[i].tripId = trips[i].trip.tripId;
      chatInfoList[i].guestAddress = trips[i].trip.guest;
      chatInfoList[i].guestName = string(abi.encodePacked(guestInfo.name, ' ', guestInfo.surname));
      chatInfoList[i].guestPhotoUrl = guestInfo.profilePhoto;
      chatInfoList[i].hostAddress = trips[i].trip.host;
      chatInfoList[i].hostName = string(abi.encodePacked(hostInfo.name, ' ', hostInfo.surname));
      chatInfoList[i].hostPhotoUrl = hostInfo.profilePhoto;
      chatInfoList[i].tripStatus = uint256(trips[i].trip.status);

      Schemas.CarInfo memory carInfo = carService.getCarInfoById(trips[i].trip.carId);
      chatInfoList[i].carBrand = carInfo.brand;
      chatInfoList[i].carModel = carInfo.model;
      chatInfoList[i].carYearOfProduction = carInfo.yearOfProduction;
      chatInfoList[i].carMetadataUrl = carService.tokenURI(trips[i].trip.carId);
      chatInfoList[i].startDateTime = trips[i].trip.startDateTime;
      chatInfoList[i].endDateTime = trips[i].trip.endDateTime;
      chatInfoList[i].timeZoneId = IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(
        carInfo.carId
      );
    }

    return chatInfoList;
  }

  /// @notice Parses a response string containing geolocation data.
  /// @param response The response string to parse.
  /// @return result Parsed geolocation data in RentalityGeoService.ParsedGeolocationData structure.
  function parseResponse(string memory response) public pure returns (Schemas.ParsedGeolocationData memory) {
    Schemas.ParsedGeolocationData memory result;

    string[] memory pairs = splitString(response, bytes('|'));
    for (uint256 i = 0; i < pairs.length; i++) {
      string[] memory keyValue = splitKeyValue(pairs[i]);
      string memory key = keyValue[0];
      string memory value = keyValue[1];
      if (compareStrings(key, 'status')) {
        result.status = value;
      } else if (compareStrings(key, 'locationLat')) {
        result.locationLat = value;
      } else if (compareStrings(key, 'locationLng')) {
        result.locationLng = value;
      } else if (compareStrings(key, 'northeastLat')) {
        result.northeastLat = value;
      } else if (compareStrings(key, 'northeastLng')) {
        result.northeastLng = value;
      } else if (compareStrings(key, 'southwestLat')) {
        result.southwestLat = value;
      } else if (compareStrings(key, 'southwestLng')) {
        result.southwestLng = value;
      } else if (compareStrings(key, 'locality')) {
        result.city = value;
      } else if (compareStrings(key, 'adminAreaLvl1')) {
        result.state = value;
      } else if (compareStrings(key, 'country')) {
        result.country = value;
      }
    }

    return result;
  }

  /// @notice Splits a string into an array of substrings based on a delimiter.
  /// @param input The input string to split.
  /// @return parts Array of substrings.
  function splitString(string memory input, bytes memory delimiterBytes) internal pure returns (string[] memory) {
    bytes memory inputBytes = bytes(input);

    uint256 delimiterCount = 0;
    for (uint256 i = 0; i < inputBytes.length; i++) {
      if (inputBytes[i] == delimiterBytes[0]) {
        delimiterCount++;
      }
    }

    string[] memory parts = new string[](delimiterCount + 1);

    uint256 partIndex = 0;
    uint256 startNewString = 0;

    for (uint256 i = 0; i < inputBytes.length; i++) {
      if (inputBytes[i] == delimiterBytes[0]) {
        bytes memory newString = new bytes(i - startNewString);
        uint256 newStringIndex = 0;
        for (uint256 j = startNewString; j < i; j++) {
          newString[newStringIndex] = inputBytes[j];
          newStringIndex++;
          startNewString++;
        }
        startNewString++;
        parts[partIndex] = string(newString);
        partIndex++;
      }
    }
    // get last part
    if (startNewString < inputBytes.length) {
      bytes memory lastString = new bytes(inputBytes.length - startNewString);
      for (uint256 j = startNewString; j < inputBytes.length; j++) {
        lastString[j - startNewString] = inputBytes[j];
      }
      parts[partIndex] = string(lastString);
    }

    return parts;
  }

  /// @notice Splits a key-value pair string into an array of key and value.
  /// @param input The input string to split.
  /// @return parts Array containing key and value.
  function splitKeyValue(string memory input) internal pure returns (string[] memory) {
    bytes memory inputBytes = bytes(input);
    bytes memory delimiterBytes = bytes('^');

    uint256 delimiterIndex = 0;
    for (uint256 i = 0; i < inputBytes.length; i++) {
      if (inputBytes[i] == delimiterBytes[0]) {
        delimiterIndex = i;
      }
    }

    string[] memory parts = new string[](2);
    bytes memory keyString = new bytes(delimiterIndex);

    for (uint256 i = 0; i < delimiterIndex; i++) {
      keyString[i] = inputBytes[i];
    }
    parts[0] = string(keyString);

    bytes memory valueString = new bytes(inputBytes.length - delimiterIndex - 1);

    uint256 startValueString = 0;
    for (uint256 i = (delimiterIndex + 1); i < inputBytes.length; i++) {
      valueString[startValueString] = inputBytes[i];
      startValueString++;
    }

    parts[1] = string(valueString);

    return parts;
  }

  /// @notice Compares two strings for equality.
  /// @param a The first string.
  /// @param b The second string.
  /// @return Returns true if the strings are equal, false otherwise.
  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(bytes(a)) == keccak256(bytes(b)));
  }

  /// @notice URL encodes a string.
  /// @param input The input string to encode.
  /// @return output The URL-encoded string.
  function urlEncode(string memory input) internal pure returns (string memory) {
    bytes memory inputBytes = bytes(input);
    string memory output = '';

    for (uint256 i = 0; i < inputBytes.length; i++) {
      bytes memory spaceBytes = bytes(' ');
      if (inputBytes[i] == spaceBytes[0]) {
        output = string(
          abi.encodePacked(
            output,
            '%',
            bytes1(uint8(inputBytes[i]) / 16 + 48),
            bytes1((uint8(inputBytes[i]) % 16) + 48)
          )
        );
      } else {
        output = string(abi.encodePacked(output, bytes1(inputBytes[i])));
      }
    }
    return output;
  }

  /// @dev Converts a bytes32 data to a bytes array.
  /// @param _data The input bytes32 data to convert.
  /// @return Returns the packed representation of the input data as a bytes array.
  function toBytes(bytes32 _data) public pure returns (bytes memory) {
    return abi.encodePacked(_data);
  }

  /// @notice This function computes various aspects of the trip receipt, including pricing, mileage, and fuel charges.
  /// @param tripId The ID of the trip for which the receipt is calculated.
  /// @param tripServiceAddress The address of the trip service contract.
  /// @return tripReceipt An instance of `Schemas.TripReceiptDTO` containing the detailed trip receipt information.
  function fullFillTripReceipt(
    uint tripId,
    address tripServiceAddress
  ) public view returns (Schemas.TripReceiptDTO memory) {
    RentalityTripService tripService = RentalityTripService(tripServiceAddress);

    Schemas.Trip memory trip = tripService.getTrip(tripId);
    uint64 ceilDays = getCeilDays(trip.startDateTime, trip.endDateTime);

    uint64 allowedMiles = trip.milesIncludedPerDay * ceilDays;

    uint64 totalMilesDriven = trip.endParamLevels[1] - trip.startParamLevels[1];

    uint64 overmiles = allowedMiles >= totalMilesDriven ? 0 : totalMilesDriven - allowedMiles;

    return
      Schemas.TripReceiptDTO(
        trip.paymentInfo.totalDayPriceInUsdCents,
        ceilDays,
        trip.paymentInfo.priceWithDiscount,
        trip.paymentInfo.totalDayPriceInUsdCents - trip.paymentInfo.priceWithDiscount,
        trip.paymentInfo.salesTax,
        trip.paymentInfo.governmentTax,
        trip.paymentInfo.depositInUsdCents,
        trip.paymentInfo.resolveAmountInUsdCents,
        trip.paymentInfo.depositInUsdCents - trip.paymentInfo.resolveAmountInUsdCents,
        trip.startParamLevels[0] >= trip.endParamLevels[0] ? 0 : trip.endParamLevels[0] - trip.startParamLevels[0],
        trip.fuelPrice,
        trip.paymentInfo.resolveFuelAmountInUsdCents,
        allowedMiles,
        overmiles,
        overmiles > 0 ? trip.paymentInfo.resolveMilesAmountInUsdCents / overmiles : 0,
        trip.paymentInfo.resolveMilesAmountInUsdCents,
        trip.startParamLevels[0],
        trip.endParamLevels[0],
        trip.startParamLevels[1],
        trip.endParamLevels[1]
      );
  }
  /// @notice Checks if a car is available for a specific user based on search parameters.
  /// @dev Determines availability based on several conditions, including ownership and search parameters.
  /// @param carId The ID of the car being checked.
  /// @param searchCarParams The parameters used to filter available cars.
  /// @return A boolean indicating whether the car is available for the user.
  function isCarAvailableForUser(
    uint256 carId,
    Schemas.SearchCarParams memory searchCarParams,
    address carServiceAddress,
    address geoServiceAddress
  ) public view returns (bool) {
    RentalityCarToken carService = RentalityCarToken(carServiceAddress);
    IRentalityGeoService geoService = IRentalityGeoService(geoServiceAddress);

    Schemas.CarInfo memory car = carService.getCarInfoById(carId);
    return
      (bytes(searchCarParams.brand).length == 0 || containWord(toLower(car.brand), toLower(searchCarParams.brand))) &&
      (bytes(searchCarParams.model).length == 0 || containWord(toLower(car.model), toLower(searchCarParams.model))) &&
      (bytes(searchCarParams.country).length == 0 ||
        containWord(toLower(geoService.getCarCountry(carId)), toLower(searchCarParams.country))) &&
      (bytes(searchCarParams.state).length == 0 ||
        containWord(toLower(geoService.getCarState(carId)), toLower(searchCarParams.state))) &&
      (bytes(searchCarParams.city).length == 0 ||
        containWord(toLower(geoService.getCarCity(carId)), toLower(searchCarParams.city))) &&
      (searchCarParams.yearOfProductionFrom == 0 || car.yearOfProduction >= searchCarParams.yearOfProductionFrom) &&
      (searchCarParams.yearOfProductionTo == 0 || car.yearOfProduction <= searchCarParams.yearOfProductionTo) &&
      (searchCarParams.pricePerDayInUsdCentsFrom == 0 ||
        car.pricePerDayInUsdCents >= searchCarParams.pricePerDayInUsdCentsFrom) &&
      (searchCarParams.pricePerDayInUsdCentsTo == 0 ||
        car.pricePerDayInUsdCents <= searchCarParams.pricePerDayInUsdCentsTo);
  }

  /// @dev Calculates the payments for a trip.
  /// @param carId The ID of the car.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param currency The currency to use for payment calculation.
  /// @param pickUpLocation lat and lon of pickUp and return locations.
  /// @param returnLocation lat and lon of pickUp and return locations.
  /// @return calculatePaymentsDTO An object containing payment details.
  function calculatePaymentsWithDelivery(
    RentalityContract memory addresses,
    uint carId,
    uint64 daysOfTrip,
    address currency,
    Schemas.LocationInfo memory pickUpLocation,
    Schemas.LocationInfo memory returnLocation
  ) public view returns (Schemas.CalculatePaymentsDTO memory) {
    uint64 deliveryFee = RentalityCarDelivery(addresses.adminService.getDeliveryServiceAddress())
      .calculatePriceByDeliveryDataInUsdCents(
        pickUpLocation,
        returnLocation,
        IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLatitude(carId),
        IRentalityGeoService(addresses.carService.getGeoServiceAddress()).getCarLocationLongitude(carId),
        addresses.carService.getCarInfoById(carId).createdBy
      );
    return calculatePayments(addresses, carId, daysOfTrip, currency, deliveryFee);
  }
  /// @notice Checks if a car is available for a specific user based on search parameters.
  /// @dev Calculates the payments for a trip.
  /// @param carId The ID of the car.
  /// @param daysOfTrip The duration of the trip in days.
  /// @param currency The currency to use for payment calculation.
  /// @return calculatePaymentsDTO An object containing payment details.
  function calculatePayments(
    RentalityContract memory addresses,
    uint carId,
    uint64 daysOfTrip,
    address currency,
    uint64 deliveryFee
  ) public view returns (Schemas.CalculatePaymentsDTO memory) {
    address carOwner = addresses.carService.ownerOf(carId);
    Schemas.CarInfo memory car = addresses.carService.getCarInfoById(carId);

    uint64 sumWithDiscount = addresses.paymentService.calculateSumWithDiscount(
      carOwner,
      daysOfTrip,
      car.pricePerDayInUsdCents
    );
    uint taxId = addresses.paymentService.defineTaxesType(address(addresses.carService), carId);

    (uint64 salesTaxes, uint64 govTax) = addresses.paymentService.calculateTaxes(
      taxId,
      daysOfTrip,
      sumWithDiscount + deliveryFee
    );
    (int rate, uint8 decimals) = addresses.currencyConverterService.getCurrentRate(currency);

    uint256 valueSumInCurrency = addresses.currencyConverterService.getFromUsd(
      currency,
      car.securityDepositPerTripInUsdCents + salesTaxes + govTax + sumWithDiscount + deliveryFee,
      rate,
      decimals
    );

    return Schemas.CalculatePaymentsDTO(valueSumInCurrency, rate, decimals);
  }

  function validateTripRequest(
    RentalityContract memory addresses,
    address currencyType,
    uint carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) public view {
    require(addresses.userService.hasPassedKYCAndTC(tx.origin), 'KYC or TC not passed.');
    require(addresses.currencyConverterService.currencyTypeIsAvailable(currencyType), 'Token is not available.');
    require(addresses.carService.ownerOf(carId) != tx.origin, 'Car is not available for creator');
    require(!isCarUnavailable(addresses, carId, startDateTime, endDateTime), 'Unavailable for current date.');
  }

  // @dev Checks if a car has any active trips within the specified time range.
  // @param carId The ID of the car to check for availability.
  // @param startDateTime The start time of the time range.
  // @param endDateTime The end time of the time range.
  // @return A boolean indicating whether the car is unavailable during the specified time range.
  function isCarUnavailable(
    RentalityContract memory addresses,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) private view returns (bool) {
    // Iterate through all trips to check for intersections with the specified car and time range.
    for (uint256 tripId = 1; tripId <= addresses.tripService.totalTripCount(); tripId++) {
      Schemas.Trip memory trip = addresses.tripService.getTrip(tripId);
      Schemas.CarInfo memory car = addresses.carService.getCarInfoById(trip.carId);

      if (
        trip.carId == carId &&
        trip.endDateTime + car.timeBufferBetweenTripsInSec > startDateTime &&
        trip.startDateTime < endDateTime
      ) {
        Schemas.TripStatus tripStatus = trip.status;

        // Check if the trip is active (not in Created, Finished, or Canceled status).
        bool isActiveTrip = (tripStatus != Schemas.TripStatus.Created &&
          tripStatus != Schemas.TripStatus.Finished &&
          tripStatus != Schemas.TripStatus.Canceled);

        // Return true if an active trip is found.
        if (isActiveTrip) {
          return true;
        }
      }
    }

    // If no active trips are found, return false indicating the car is available.
    return false;
  }

  function createPaymentInfo(
    RentalityContract memory addresses,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime,
    address currencyType,
    uint64 deliveryFee
  ) public view returns (Schemas.PaymentInfo memory, uint) {
    Schemas.CarInfo memory carInfo = addresses.carService.getCarInfoById(carId);

    uint64 daysOfTrip = getCeilDays(startDateTime, endDateTime);

    uint64 priceWithDiscount = addresses.paymentService.calculateSumWithDiscount(
      addresses.carService.ownerOf(carId),
      daysOfTrip,
      carInfo.pricePerDayInUsdCents
    );
    uint taxId = addresses.paymentService.defineTaxesType(address(addresses.carService), carId);

    (uint64 salesTaxes, uint64 govTax) = addresses.paymentService.calculateTaxes(
      taxId,
      daysOfTrip,
      priceWithDiscount + deliveryFee
    );

    uint valueSum = priceWithDiscount + salesTaxes + govTax + carInfo.securityDepositPerTripInUsdCents + deliveryFee;
    (int rate, uint8 decimals) = addresses.currencyConverterService.getCurrentRate(currencyType);
    uint valueSumInCurrency = addresses.currencyConverterService.getFromUsd(currencyType, valueSum, rate, decimals);

    Schemas.PaymentInfo memory paymentInfo = Schemas.PaymentInfo(
      0,
      tx.origin,
      address(this),
      carInfo.pricePerDayInUsdCents * daysOfTrip,
      salesTaxes,
      govTax,
      priceWithDiscount,
      carInfo.securityDepositPerTripInUsdCents,
      0,
      currencyType,
      rate,
      decimals,
      0,
      0,
      deliveryFee
    );

    return (paymentInfo, valueSumInCurrency);
  }

  /// @notice Get contact information for a specific trip on the Rentality platform.
  /// @param tripId The ID of the trip to retrieve contact information for.
  /// @return guestPhoneNumber The phone number of the guest on the trip.
  /// @return hostPhoneNumber The phone number of the host on the trip.
  //// Refactoring for getTripContactInfo with RentalityContract
  function getTripContactInfo(
    uint256 tripId,
    address tripService,
    address userService
  ) public view returns (string memory guestPhoneNumber, string memory hostPhoneNumber) {
    require(RentalityUserService(userService).isHostOrGuest(tx.origin), 'User is not a host or guest');

    Schemas.Trip memory trip = RentalityTripService(tripService).getTrip(tripId);

    Schemas.KYCInfo memory guestInfo = RentalityUserService(userService).getKYCInfo(trip.guest);
    Schemas.KYCInfo memory hostInfo = RentalityUserService(userService).getKYCInfo(trip.host);

    return (guestInfo.mobilePhoneNumber, hostInfo.mobilePhoneNumber);
  }

  /// @dev Retrieves delivery data for a given car.
  /// @param carId The ID of the car for which delivery data is requested.
  /// @return deliveryData The delivery data including location details and delivery prices.
  function getDeliveryData(
    RentalityContract memory addresses,
    uint carId
  ) public view returns (Schemas.DeliveryData memory) {
    IRentalityGeoService geoService = IRentalityGeoService(addresses.carService.getGeoServiceAddress());

    Schemas.DeliveryPrices memory deliveryPrices = RentalityCarDelivery(
      addresses.adminService.getDeliveryServiceAddress()
    ).getUserDeliveryPrices(addresses.carService.ownerOf(carId));

    return
      Schemas.DeliveryData(
        geoService.getLocationInfo(addresses.carService.getCarInfoById(carId).locationHash),
        deliveryPrices.underTwentyFiveMilesInUsdCents,
        deliveryPrices.aboveTwentyFiveMilesInUsdCents,
        addresses.carService.getCarInfoById(carId).insuranceIncluded
      );
  }

  function getTripsByGuest(
    RentalityContract memory contracts,
    address guest
  ) public view returns (Schemas.TripDTO[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).guest == guest) {
        itemCount += 1;
      }
    }

    Schemas.TripDTO[] memory result = new Schemas.TripDTO[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).guest == guest) {
        result[currentIndex] = getTripDTO(contracts, i);

        currentIndex += 1;
      }
    }

    return result;
  }

  function getTripsByHost(
    RentalityContract memory contracts,
    address host
  ) public view returns (Schemas.TripDTO[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).host == host) {
        itemCount += 1;
      }
    }

    Schemas.TripDTO[] memory result = new Schemas.TripDTO[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).host == host) {
        result[currentIndex] = getTripDTO(contracts, i);
        currentIndex += 1;
      }
    }

    return result;
  }

  // Updated function getTripDTO with RentalityContract parameter
  function getTripDTO(RentalityContract memory contracts, uint tripId) public view returns (Schemas.TripDTO memory) {
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;

    Schemas.Trip memory trip = tripService.getTrip(tripId);
    Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);

    Schemas.LocationInfo memory pickUpLocation = IRentalityGeoService(carService.getGeoServiceAddress())
      .getLocationInfo(trip.pickUpHash);
    Schemas.LocationInfo memory returnLocation = IRentalityGeoService(carService.getGeoServiceAddress())
      .getLocationInfo(trip.returnHash);
    return
      Schemas.TripDTO(
        trip,
        userService.getKYCInfo(trip.guest).profilePhoto,
        userService.getKYCInfo(trip.host).profilePhoto,
        carService.tokenURI(trip.carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(trip.carId),
        userService.getKYCInfo(trip.host).licenseNumber,
        userService.getKYCInfo(trip.host).expirationDate,
        userService.getKYCInfo(trip.guest).licenseNumber,
        userService.getKYCInfo(trip.guest).expirationDate,
        car.model,
        car.brand,
        car.yearOfProduction,
        bytes(pickUpLocation.latitude).length == 0
          ? IRentalityGeoService(carService.getGeoServiceAddress()).getLocationInfo(car.locationHash)
          : pickUpLocation,
        bytes(pickUpLocation.latitude).length == 0
          ? IRentalityGeoService(carService.getGeoServiceAddress()).getLocationInfo(car.locationHash)
          : returnLocation
      );
  }
}
