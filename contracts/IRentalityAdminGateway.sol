// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Rentality Admin Gateway Interface
/// @dev Interface for the RentalityAdminGateway contract,
/// providing administrative functionalities for the Rentality platform.
interface IRentalityAdminGateway {
  /// @notice Retrieves the address of the RentalityCarToken contract.
  /// @return The address of the RentalityCarToken contract.
  function getCarServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCarToken contract.
  function updateCarService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityPayment contract.
  /// @return The address of the RentalityPayment contract.
  function getPaymentService() external view returns (address);

  /// @notice Updates the address of the RentalityCarToken contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityPayment contract.
  function updatePaymentService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityClaim contract.
  /// @return The address of the RentalityClaim contract.
  function getClaimServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityClaim contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityClaim contract.
  function updateClaimService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityPlatform contract.
  /// @return The address of the RentalityPlatform contract.
  function getRentalityPlatformAddress() external view returns (address);

  /// @notice Updates the address of the RentalityPlatform contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityPlatform contract.
  function updateRentalityPlatform(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityCurrencyConverter contract.
  /// @return The address of the RentalityCurrencyConverter contract.
  function getCurrencyConverterServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityCurrencyConverter contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityCurrencyConverter contract.
  function updateCurrencyConverterService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityTripService contract.
  /// @return The address of the RentalityTripService contract.
  function getTripServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityTripService contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityTripService contract.
  function updateTripService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityUserService contract.
  /// @return The address of the RentalityUserService contract.
  function getUserServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityUserService contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityUserService contract.
  function updateUserService(address contractAddress) external;

  /// @notice Retrieves the address of the RentalityAutomation contract.
  /// @return The address of the RentalityAutomation contract.
  function getAutomationServiceAddress() external view returns (address);

  /// @notice Updates the address of the RentalityAutomation contract. Only callable by admins.
  /// @param contractAddress The new address of the RentalityAutomationService contract.
  function updateAutomationService(address contractAddress) external;

  /// @notice Withdraws the specified amount from the RentalityPlatform contract.
  /// @param amount The amount to withdraw.
  function withdrawFromPlatform(uint256 amount) external;

  /// @notice Withdraws the entire balance from the RentalityPlatform contract.
  function withdrawAllFromPlatform() external;

  /// @notice Sets the platform fee in parts per million (PPM). Only callable by admins.
  /// @param valueInPPM The new platform fee value in PPM.
  function setPlatformFeeInPPM(uint32 valueInPPM) external;

  /// @dev Sets the auto-cancellation time for all trips.
  /// @param time The new auto-cancellation time in hours. Must be between 1 and 24.
  /// @notice Only the administrator can call this function.
  function setAutoCancellationTime(uint8 time) external;

  /// @dev Retrieves the current auto-cancellation time for all trips.
  /// @return The current auto-cancellation time in hours.
  function getAutoCancellationTimeInSec() external view returns (uint64);

  /// @dev Sets the auto status change time for all trips.
  /// @param time The new auto status change time in hours. Must be between 1 and 3.
  /// @notice Only the administrator can call this function.
  function setAutoStatusChangeTime(uint8 time) external;

  /// @dev Retrieves the current auto status change time for all trips.
  /// @return The current auto status change time in hours.
  function getAutoStatusChangeTimeInSec() external view returns (uint64);

  /// @dev Sets the waiting time, only callable by administrators.
  /// @param timeInSec, set old value to this
  function setClaimsWaitingTime(uint timeInSec) external;

  /// @dev get waiting time to approval
  /// @return waiting time to approval in sec
  function getClaimWaitingTime() external view returns (uint);
}
