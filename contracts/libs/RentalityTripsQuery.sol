/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../RentalityCarToken.sol';
import '../payments/RentalityCurrencyConverter.sol';
import '../payments/RentalityPaymentService.sol';
import '../RentalityTripService.sol';
import '../RentalityUserService.sol';
import '../RentalityPlatform.sol';
import '../features/RentalityClaimService.sol';
import '../RentalityAdminGateway.sol';
import '../RentalityGateway.sol';
import {IRentalityGeoService} from '../abstract/IRentalityGeoService.sol';
import {RentalityCarDelivery} from '../features/RentalityCarDelivery.sol';
import '../Schemas.sol';
import './RentalityUtils.sol';
import './RentalityQuery.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';

library RentalityTripsQuery {
  /// @notice Checks if a trip intersects with the specified time interval.
  /// @dev This function checks whether the trip's scheduled time overlaps with the given time interval,
  /// taking into account any buffer time between trips.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param tripId The ID of the trip to check.
  /// @param startDateTime The start time of the interval to check for intersection.
  /// @param endDateTime The end time of the interval to check for intersection.
  /// @return Returns true if the trip intersects with the specified time interval, otherwise false.
  function isTripThatIntersect(
    RentalityContract memory contracts,
    uint256 tripId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (bool) {
    Schemas.Trip memory trip = contracts.tripService.getTrip(tripId);
    Schemas.CarInfo memory carInfo = contracts.carService.getCarInfoById(trip.carId);
    return
      (trip.endDateTime + carInfo.timeBufferBetweenTripsInSec > startDateTime) && (trip.startDateTime < endDateTime);
  }

  /// @notice Retrieves all trips for a specific car that intersect with the given time interval.
  /// @dev This function checks all trips associated with a car and returns those that overlap with the specified time period.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param carId The ID of the car to check.
  /// @param startDateTime The start time of the interval to check for intersection.
  /// @param endDateTime The end time of the interval to check for intersection.
  /// @return An array of Trip structures representing trips that intersect with the specified time interval.
  function getTripsForCarThatIntersect(
    RentalityContract memory contracts,
    uint256 carId,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (Schemas.Trip[] memory) {
    uint itemCount = 0;
    RentalityTripService tripService = contracts.tripService;

    uint32 timeBuffer = contracts.carService.getCarInfoById(carId).timeBufferBetweenTripsInSec;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (RentalityQuery.isCarThatIntersect(contracts, currentId, carId, startDateTime, endDateTime + timeBuffer)) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (RentalityQuery.isCarThatIntersect(contracts, currentId, carId, startDateTime, endDateTime + timeBuffer)) {
        result[currentIndex] = tripService.getTrip(currentId);
        currentIndex += 1;
      }
    }

    return result;
  }

  /// @notice Retrieves all trips associated with a specific car.
  /// @dev This function fetches all trips where the car with the specified ID is used.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param carId The ID of the car to check.
  /// @return An array of Trip structures representing all trips associated with the specified car.
  function getTripsByCar(
    RentalityContract memory contracts,
    uint256 carId
  ) public view returns (Schemas.Trip[] memory) {
    RentalityTripService tripService = contracts.tripService;
    uint itemCount = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).carId == carId) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 1; i <= tripService.totalTripCount(); i++) {
      if (tripService.getTrip(i).carId == carId) {
        Schemas.Trip memory currentItem = tripService.getTrip(i);
        result[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }

    return result;
  }

  /// @notice Retrieves all trips that intersect with the specified time interval.
  /// @dev This function checks all trips and returns those that overlap with the specified time period.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param startDateTime The start time of the interval to check for intersection.
  /// @param endDateTime The end time of the interval to check for intersection.
  /// @return An array of Trip structures representing trips that intersect with the specified time interval.
  function getTripsThatIntersect(
    RentalityContract memory contracts,
    uint64 startDateTime,
    uint64 endDateTime
  ) internal view returns (Schemas.Trip[] memory) {
    uint itemCount = 0;
    RentalityTripService tripService = contracts.tripService;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (isTripThatIntersect(contracts, currentId, startDateTime, endDateTime)) {
        itemCount += 1;
      }
    }

    Schemas.Trip[] memory result = new Schemas.Trip[](itemCount);
    uint currentIndex = 0;

    for (uint i = 0; i < tripService.totalTripCount(); i++) {
      uint currentId = i + 1;
      if (isTripThatIntersect(contracts, currentId, startDateTime, endDateTime)) {
        result[currentIndex] = tripService.getTrip(currentId);
        currentIndex += 1;
      }
    }

    return result;
  }

  /// @notice Calculates the detailed receipt for a specific trip.
  /// @dev This function computes various aspects of the trip receipt, including pricing, mileage, and fuel charges.
  /// @param tripId The ID of the trip for which the receipt is calculated.
  /// @param tripServiceAddress The address of the trip service contract.
  /// @return An instance of `Schemas.TripReceiptDTO` containing the detailed trip receipt information.
  function fullFillTripReceipt(
    uint tripId,
    address tripServiceAddress
  ) public view returns (Schemas.TripReceiptDTO memory) {
    RentalityTripService tripService = RentalityTripService(tripServiceAddress);

    Schemas.Trip memory trip = tripService.getTrip(tripId);
    uint64 ceilDays = RentalityUtils.getCeilDays(trip.startDateTime, trip.endDateTime);

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
        overmiles > 0 ? uint64(Math.ceilDiv(trip.paymentInfo.totalDayPriceInUsdCents, trip.milesIncludedPerDay)) : 0,
        trip.paymentInfo.resolveMilesAmountInUsdCents,
        trip.startParamLevels[0],
        trip.endParamLevels[0],
        trip.startParamLevels[1],
        trip.endParamLevels[1]
      );
  }

  /// @notice Retrieves contact information for a specific trip.
  /// @dev This function returns the phone numbers of the guest and host for a given trip.
  /// @param tripId The ID of the trip to retrieve contact information for.
  /// @param tripService The address of the trip service contract.
  /// @param userService The address of the user service contract.
  /// @return guestPhoneNumber The phone number of the guest on the trip.
  /// @return hostPhoneNumber The phone number of the host on the trip.
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

  function getTripsAs(
    RentalityContract memory contracts,
    address user,
    bool host
  ) public view returns (Schemas.TripDTO[] memory) {
    return
      host ? getTripsByHost(contracts, user) : getTripsByGuest(contracts, user);
  }

  /// @notice Retrieves all trips associated with a specific guest.
  /// @dev This function fetches all trips where the specified guest is involved.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param guest The address of the guest to check.
  /// @return An array of TripDTO structures representing all trips associated with the specified guest.
  function getTripsByGuest(
    RentalityContract memory contracts,
    address guest
  ) private view returns (Schemas.TripDTO[] memory) {
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

  /// @notice Retrieves all trips associated with a specific host.
  /// @dev This function fetches all trips where the specified host is involved.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param host The address of the host to check.
  /// @return An array of TripDTO structures representing all trips associated with the specified host.
  function getTripsByHost(
    RentalityContract memory contracts,
    address host
  ) private view returns (Schemas.TripDTO[] memory) {
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

  /// @notice Retrieves detailed information about a specific trip.
  /// @dev This function fetches all relevant data for a trip including car, user, and location information.
  /// @param contracts The Rentality contract instance containing service addresses.
  /// @param tripId The ID of the trip to retrieve.
  /// @return An instance of TripDTO containing all relevant information about the trip.
  function getTripDTO(
    RentalityContract memory contracts,
    uint tripId
  ) public view returns (Schemas.TripDTO memory) {
    RentalityTripService tripService = contracts.tripService;
    RentalityCarToken carService = contracts.carService;
    RentalityUserService userService = contracts.userService;

    Schemas.Trip memory trip = tripService.getTrip(tripId);
    Schemas.CarInfo memory car = carService.getCarInfoById(trip.carId);

    Schemas.LocationInfo memory pickUpLocation = IRentalityGeoService(carService.getGeoServiceAddress())
      .getLocationInfo(trip.pickUpHash);
    Schemas.LocationInfo memory returnLocation = IRentalityGeoService(carService.getGeoServiceAddress())
      .getLocationInfo(trip.returnHash);
    (string memory guestPhoneNumber, string memory hostPhoneNumber) = getTripContactInfo(
      tripId,
      address(tripService),
      address(userService)
    );
    return
      Schemas.TripDTO(
        trip,
        userService.getKYCInfo(trip.guest).profilePhoto,
        userService.getKYCInfo(trip.host).profilePhoto,
        carService.tokenURI(trip.carId),
        IRentalityGeoService(carService.getGeoServiceAddress()).getCarTimeZoneId(car.locationHash),
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
          : returnLocation,
        guestPhoneNumber,
        hostPhoneNumber
      );
  }

  // @notice Retrieves all trips based on the provided filter and pagination.
  /// @param filter The filter to apply to the trips.
  /// @param page The current page number.
  /// @param itemsPerPage The number of items per page.
  /// @return A structure containing the filtered trips and total page count.
  function getAllTrips(
    RentalityContract memory contracts,
    Schemas.TripFilter memory filter,
    uint page,
    uint itemsPerPage
  ) public view returns (Schemas.AllTripsDTO memory) {
    uint totalTripsCount = contracts.tripService.totalTripCount();

    uint[] memory matchedTrips = new uint[](totalTripsCount);

    uint counter = 0;
    for (uint i = 1; i <= totalTripsCount; i++) {
      if (isTripMatch(contracts, filter, contracts.tripService.getTrip(i))) {
        matchedTrips[counter] = i;
        counter += 1;
      }
    }
    if (counter == 0) return Schemas.AllTripsDTO(new Schemas.AdminTripDTO[](0), 0);

    uint totalPageCount = (counter + itemsPerPage - 1) / itemsPerPage;

    if (page > totalPageCount) {
      page = totalPageCount;
    }

    uint startIndex = (page - 1) * itemsPerPage;
    uint endIndex = startIndex + itemsPerPage;

    if (endIndex > counter) {
      endIndex = counter;
    }

    Schemas.AdminTripDTO[] memory result = new Schemas.AdminTripDTO[](endIndex - startIndex);
    for (uint i = startIndex; i < endIndex; i++) {
      Schemas.Trip memory trip = contracts.tripService.getTrip(matchedTrips[i]);
      Schemas.CarInfo memory car = contracts.carService.getCarInfoById(trip.carId);
      result[i - startIndex] = Schemas.AdminTripDTO(
        trip,
        contracts.carService.tokenURI(trip.carId),
        IRentalityGeoService(contracts.carService.getGeoServiceAddress()).getLocationInfo(car.locationHash)
      );
    }

    return Schemas.AllTripsDTO(result, totalPageCount);
  }

  // @notice Checks if a trip matches the provided filter.
  /// @dev This function is used internally to filter trips based on the given criteria.
  /// @param filter The filter to apply.
  /// @param trip The trip to check against the filter.
  /// @return Returns true if the trip matches the filter, otherwise false.
  function isTripMatch(
    RentalityContract memory contracts,
    Schemas.TripFilter memory filter,
    Schemas.Trip memory trip
  ) internal view returns (bool) {
    IRentalityGeoService geoService = IRentalityGeoService(contracts.carService.getGeoServiceAddress());
    Schemas.LocationInfo memory locationInfo = geoService.getLocationInfo(
      contracts.carService.getCarInfoById(trip.carId).locationHash
    );
    return ((bytes(filter.location.country).length == 0 ||
      RentalityUtils.containWord(
        RentalityUtils.toLower(locationInfo.country),
        RentalityUtils.toLower(filter.location.country)
      )) &&
      (bytes(filter.location.state).length == 0 ||
        RentalityUtils.containWord(
          RentalityUtils.toLower(locationInfo.state),
          RentalityUtils.toLower(filter.location.state)
        )) &&
      (bytes(filter.location.city).length == 0 ||
        RentalityUtils.containWord(
          RentalityUtils.toLower(locationInfo.city),
          RentalityUtils.toLower(filter.location.city)
        )) &&
      (filter.startDateTime <= trip.startDateTime && filter.endDateTime >= trip.endDateTime) &&
      (filter.paymentStatus == Schemas.PaymentStatus.Any ||
        (filter.paymentStatus == Schemas.PaymentStatus.PaidToHost && trip.status == Schemas.TripStatus.Finished) ||
        (filter.paymentStatus == Schemas.PaymentStatus.Prepayment &&
          (trip.status == Schemas.TripStatus.Created ||
            trip.status == Schemas.TripStatus.Approved ||
            trip.status == Schemas.TripStatus.CheckedInByHost ||
            (trip.status == Schemas.TripStatus.CheckedInByGuest && trip.tripStartedBy == trip.guest) ||
            (trip.status == Schemas.TripStatus.CheckedOutByGuest && trip.tripFinishedBy == trip.guest) ||
            (trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.guest))) ||
        (filter.paymentStatus == Schemas.PaymentStatus.RefundToGuest && trip.status == Schemas.TripStatus.Canceled) ||
        (filter.paymentStatus == Schemas.PaymentStatus.Unpaid &&
          ((trip.status == Schemas.TripStatus.CheckedInByGuest && trip.tripStartedBy == trip.host) ||
            (trip.status == Schemas.TripStatus.CheckedOutByHost && trip.tripFinishedBy == trip.host)))) &&
      (filter.status == Schemas.AdminTripStatus.Any ||
        (filter.status == Schemas.AdminTripStatus.Created && trip.status == Schemas.TripStatus.Created) ||
        (filter.status == Schemas.AdminTripStatus.Approved && trip.status == Schemas.TripStatus.Approved) ||
        (filter.status == Schemas.AdminTripStatus.CheckedInByHost &&
          trip.status == Schemas.TripStatus.CheckedInByHost) ||
        (filter.status == Schemas.AdminTripStatus.CheckedInByGuest &&
          trip.status == Schemas.TripStatus.CheckedInByGuest &&
          trip.tripStartedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.CheckedOutByGuest &&
          trip.status == Schemas.TripStatus.CheckedOutByGuest &&
          trip.tripFinishedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.CheckedOutByHost &&
          trip.status == Schemas.TripStatus.CheckedOutByHost &&
          trip.tripFinishedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.Finished && trip.status == Schemas.TripStatus.Finished) ||
        (filter.status == Schemas.AdminTripStatus.GuestCanceledBeforeApprove &&
          trip.status == Schemas.TripStatus.Canceled &&
          trip.approvedDateTime == 0 &&
          trip.rejectedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.HostCanceledBeforeApprove &&
          trip.status == Schemas.TripStatus.Canceled &&
          trip.approvedDateTime == 0 &&
          trip.rejectedBy == trip.host) ||
        (filter.status == Schemas.AdminTripStatus.GuestCanceledAfterApprove &&
          trip.status == Schemas.TripStatus.Canceled &&
          trip.approvedDateTime > 0 &&
          trip.rejectedBy == trip.guest) ||
        (filter.status == Schemas.AdminTripStatus.HostCanceledAfterApprove &&
          trip.status == Schemas.TripStatus.Canceled &&
          trip.approvedDateTime > 0 &&
          trip.rejectedBy == trip.host) ||
        (filter.status == Schemas.AdminTripStatus.CompletedWithoutGuestConfirmation &&
          trip.status == Schemas.TripStatus.CheckedOutByHost &&
          trip.tripFinishedBy == trip.host) ||
        (filter.status == Schemas.AdminTripStatus.CompletedByGuest &&
          trip.status == Schemas.TripStatus.Finished &&
          trip.tripFinishedBy == trip.host) ||
        (filter.status == Schemas.AdminTripStatus.CompletedByAdmin &&
          trip.status == Schemas.TripStatus.Finished &&
          contracts.tripService.completedByAdmin(trip.tripId))));
  }
}
