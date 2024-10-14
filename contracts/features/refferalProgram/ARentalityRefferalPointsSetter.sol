// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../../abstract/IRentalityAccessControl.sol';
import '../../Schemas.sol';
import {ARentalityRefferal} from './ARentalityRefferal.sol';

struct Points {
  bytes4 callback;
  int points;
  int pointsWithRefferalCode;
}

abstract contract ARentalityRefferalPointsSetter is ARentalityRefferal {
  address internal refferalLib;

  mapping(Schemas.RefferalProgram => mapping(address => bool)) private selectorToPassedAddress;
  mapping(Schemas.RefferalProgram => Points) internal selectorToPoints;
  mapping(Schemas.RefferalProgram => Points) internal permanentSelectorToPoints;

  mapping(address => uint) internal addressToLastDailyClaim;

  mapping(uint => uint) internal carIdToListedClaimTime;

  function updateDaily() public returns (uint) {
    uint result = 0;
    uint last = addressToLastDailyClaim[tx.origin];
    uint current = block.timestamp;
    if (last < current + 1 days) {
      addressToLastDailyClaim[tx.origin] = block.timestamp;
      result = uint(permanentSelectorToPoints[Schemas.RefferalProgram.Daily].points);
    }
    return result;
  }
  function _checkDaily(address user) internal view returns (uint) {
    uint result = 0;
    uint last = addressToLastDailyClaim[user];
    uint current = block.timestamp;
    if (last < current + 1 days) {
      result = uint(permanentSelectorToPoints[Schemas.RefferalProgram.Daily].points);
    }
    return result;
  }
  function addPermanentProgram(Schemas.RefferalProgram selector, int points, bytes4 calback) public {
    require(getUserService().isManager(msg.sender), 'only Manager');

    Points storage oldPoints = permanentSelectorToPoints[selector];

    oldPoints.callback = calback;
    oldPoints.points = points;
  }
  function addOneTimeProgram(Schemas.RefferalProgram selector, int points, int refPoints, bytes4 calback) public {
    require(getUserService().isManager(msg.sender), 'only Manager');
    Points storage oldPoints = selectorToPoints[selector];

    oldPoints.callback = calback;
    oldPoints.points = points;
    oldPoints.pointsWithRefferalCode = refPoints;
  }

  function _setPassedIfExists(
    Schemas.RefferalProgram selector,
    bytes memory callbackArgs,
    bool hasRefferalCode,
    address user
  ) internal returns (int, bool) {
    Points memory points = selectorToPoints[selector];

    int result = 0;
    bool isOneTime = true;
    if (points.points != 0) {
      bool passed = selectorToPassedAddress[selector][user];
      if (passed) {
        points = permanentSelectorToPoints[selector];
        isOneTime = false;
      } else {
        selectorToPassedAddress[selector][user] = true;
        if (hasRefferalCode) points.points = points.pointsWithRefferalCode;
      }
    } else {
      points = permanentSelectorToPoints[selector];
      isOneTime = false;
    }
    if (points.callback != bytes4('')) {
      (bool ok, bytes memory callbackResult) = refferalLib.staticcall(
        abi.encodeWithSelector(points.callback, points.points, callbackArgs)
      );
      require(ok, 'Fail to calculate points');
      points.points = abi.decode(callbackResult, (int));
    }
    return (points.points, isOneTime);
  }

  function _isOneTimeProgramExists(Schemas.RefferalProgram selector) internal view returns (bool) {
    return selectorToPoints[selector].points != 0;
  }

  function _isPermanentProgramExists(Schemas.RefferalProgram selector) internal view returns (bool) {
    return permanentSelectorToPoints[selector].points != 0;
  }
}
