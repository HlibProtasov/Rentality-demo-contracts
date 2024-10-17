// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/Math.sol';
import {RentalityReferralProgram} from './../features/refferalProgram/RentalityReferralProgram.sol';
import {RentalityCarToken} from '../RentalityCarToken.sol';
import '../Schemas.sol';

library RentalityRefferalLib {
  function finishTrip(int points, bytes memory data) public pure returns (int) {
    (uint64 startDateTime, uint64 endDateTime) = abi.decode(data, (uint64, uint64));
    uint64 duration = endDateTime - startDateTime;
    return points * int(Math.ceilDiv(duration, 1 days));
  }
  function updateCar(int points, bytes memory data) public pure returns (int) {
    (bool wasListed, bool toBeListed) = abi.decode(data, (bool, bool));
    if (!wasListed) return 0;
    if (!toBeListed) return points;

    return points;
  }
  function calculateListedCarsPoints(
    int points,
    address user,
    RentalityCarToken carService,
    RentalityReferralProgram refferalProgram
  ) internal view returns (uint, uint[] memory) {
    uint totalPoints = 0;
    uint counter = 0;
    if (carService.balanceOf(user) == 0) return (0, new uint[](0));
    for (uint i = 1; i <= carService.totalSupply(); i++) {
      if (carService.ownerOf(i) == user) {
        uint listingMoment = carService.getListingMoment(i);
        if (listingMoment != 0) {
          uint updateTime = refferalProgram.getCarDailyClaimedTime(i);
          if (updateTime > listingMoment) listingMoment = updateTime;

          uint duration = block.timestamp - listingMoment;
          uint pointsToGet = uint(points) * Math.ceilDiv(duration, 1 days);
          if (pointsToGet > 0) {
            totalPoints += pointsToGet;
            counter += 1;
          }
        }
      }
    }
    uint[] memory carIds = new uint[](counter);
    uint index = 0;
    for (uint i = 1; i <= carService.totalSupply(); i++) {
      if (carService.ownerOf(i) == user) {
        uint listingMoment = carService.getListingMoment(i);
        if (listingMoment != 0) {
          uint updateTime = refferalProgram.getCarDailyClaimedTime(i);
          if (updateTime > listingMoment) listingMoment = updateTime;
          uint duration = block.timestamp - listingMoment;
          uint pointsToGet = uint(points) * Math.ceilDiv(duration, 1 days);
          if (pointsToGet > 0) {
            carIds[index] = i;
            index += 1;
          }
        }
      }
    }
    return (totalPoints, carIds);
  }

  function updateDaily(int, bytes memory data) public returns (int) {
    (address refferalService,address user) = abi.decode(data, (address, address));
    return int(RentalityReferralProgram(refferalService).updateDaily(user));
  }

  function formatReadyToClaim(
    Schemas.ReadyToClaimDTO memory toClaim
  ) public view returns (Schemas.ReadyToClaimDTO memory) {
    Schemas.ReadyToClaim[] memory claim = new Schemas.ReadyToClaim[](uint(type(Schemas.RefferalProgram).max));
    for (uint i = 0; i < uint(type(Schemas.RefferalProgram).max); i++) {
      claim[i].refType = Schemas.RefferalProgram(i);
    }
    for (uint i = 0; i < toClaim.toClaim.length; i++) {
      for (uint j = 0; j < claim.length; j++)
        if (claim[j].refType == toClaim.toClaim[i].refType) {
          claim[j].points += toClaim.toClaim[i].points;
          claim[j].oneTime = toClaim.toClaim[i].oneTime;
        }
    }
    toClaim.toClaim = claim;
    return toClaim;
  }
  // function addCar(int points)
}
