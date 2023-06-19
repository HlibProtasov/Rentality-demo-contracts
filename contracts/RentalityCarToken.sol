// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC4907.sol";
import "./RentalityUserService.sol";

//deployed 26.05.2023 11:15 to sepolia at 0xcC66CdAfc3C39d96651220975855202960C08747
contract RentalityCarToken is ERC4907, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _carIdCounter;

    //The structure to store info about a listed car
    struct CarInfo {
        uint256 carId;
        string carVinNumber;
        bytes32 carVinNumberHash;
        address createdBy;
        uint64 pricePerDayInUsdCents;
        uint64 securityDepositPerTripInUsdCents;
        uint64 tankVolumeInGal;
        uint64 fuelPricePerGalInUsdCents;
        uint64 milesIncludedPerDay;
        string country;
        string state;
        string city;
        uint64 locationLatitudeInPPM;
        uint64 locationLongitudeInPPM;
        bool currentlyListed;
    }

    struct CreateCarRequest {
        string tokenUri;
        string carVinNumber;
        uint64 pricePerDayInUsdCents;
        uint64 securityDepositPerTripInUsdCents;
        uint64 tankVolumeInGal;
        uint64 fuelPricePerGalInUsdCents;
        uint64 milesIncludedPerDay;
        string country;
        string state;
        string city;
        uint64 locationLatitudeInPPM;
        uint64 locationLongitudeInPPM;
    }

    event CarAddedSuccess(
        string carVinNumber,
        address createdBy,
        uint64 pricePerDayInUsdCents,
        bool currentlyListed
    );

    mapping(uint256 => CarInfo) private idToCarInfo;
    RentalityUserService private userService;

    constructor(
        address userServiceAddress
    ) ERC4907("RentalityCarToken Test", "RTCT") {
        userService = RentalityUserService(userServiceAddress);
    }

    modifier onlyAdmin() {
        require(
            userService.isAdmin(msg.sender) ||
                userService.isAdmin(tx.origin) ||
                (tx.origin == owner()),
            "User is not an admin"
        );
        _;
    }

    modifier onlyHost() {
        require(userService.isHost(tx.origin), "User is not a host");
        _;
    }

    function updateUserService(address contractAddress) public onlyAdmin {
        userService = RentalityUserService(contractAddress);
    }

    function totalSupply() public view returns (uint) {
        return _carIdCounter.current();
    }

    function getCarInfoById(
        uint256 carId
    ) public view returns (CarInfo memory) {
        return idToCarInfo[carId];
    }

    function isUniqueVinNumber(
        string memory carVinNumber
    ) public view returns (bool) {
        bytes32 carVinNumberHash = keccak256(abi.encodePacked(carVinNumber));

        for (uint i = 0; i < totalSupply(); i++) {
            if (idToCarInfo[i + 1].carVinNumberHash == carVinNumberHash)
                return false;
        }

        return true;
    }

    function addCar(
        CreateCarRequest memory request
    ) public onlyHost returns (uint) {
        require(
            request.pricePerDayInUsdCents > 0,
            "Make sure the price isn't negative"
        );
        require(
            request.tankVolumeInGal > 0,
            "Make sure the tank volume isn't negative"
        );
        require(
            request.milesIncludedPerDay > 0,
            "Make sure the included distance isn't negative"
        );
        require(
            isUniqueVinNumber(request.carVinNumber),
            "Car with this VIN number is already exist"
        );

        _carIdCounter.increment();
        uint256 newCarId = _carIdCounter.current();

        _safeMint(tx.origin, newCarId);
        _setTokenURI(newCarId, request.tokenUri);

        idToCarInfo[newCarId] = CarInfo(
            newCarId,
            request.carVinNumber,
            keccak256(abi.encodePacked(request.carVinNumber)),
            tx.origin,
            request.pricePerDayInUsdCents,
            request.securityDepositPerTripInUsdCents,
            request.tankVolumeInGal,
            request.fuelPricePerGalInUsdCents,
            request.milesIncludedPerDay,
            request.country,
            request.state,
            request.city,
            request.locationLatitudeInPPM,
            request.locationLongitudeInPPM,
            true
        );

        _approve(address(this), newCarId);
        //_transfer(msg.sender, address(this), carId);

        emit CarAddedSuccess(
            request.carVinNumber,
            tx.origin,
            request.pricePerDayInUsdCents,
            true
        );

        return newCarId;
    }

    function updateCarInfo(
        uint256 carId,
        uint64 pricePerDayInUsdCents,
        bool currentlyListed
    ) public onlyHost {
        require(_exists(carId), "Token does not exist");
        require(
            ownerOf(carId) == tx.origin,
            "Only owner of the car can update car info"
        );

        idToCarInfo[carId].pricePerDayInUsdCents = pricePerDayInUsdCents;
        idToCarInfo[carId].currentlyListed = currentlyListed;
    }

    function updateCarTokenUri(
        uint256 carId,
        string memory tokenUri
    ) public onlyHost {
        require(_exists(carId), "Token does not exist");
        require(
            ownerOf(carId) == tx.origin,
            "Only owner of the car can update token"
        );

        _setTokenURI(carId, tokenUri);
    }

    function burnCar(uint256 carId) public onlyHost {
        require(_exists(carId), "Token does not exist");
        require(
            ownerOf(carId) == tx.origin,
            "Only owner of the car can burn token"
        );

        _burn(carId);
        delete idToCarInfo[carId];
    }

    function getAllCars() public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (_exists(currentId)) {
                itemCount += 1;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);

        for (uint i = 0; i < totalSupply(); i++) {
            result[i] = idToCarInfo[i + 1];
        }

        return result;
    }

    function isCarAvailableForUser(
        uint256 carId,
        address sender
    ) private view returns (bool) {
        return
            _exists(carId) &&
            idToCarInfo[carId].currentlyListed &&
            ownerOf(carId) != sender &&
            userOf(carId) == address(0);
    }

    function getAvailableCarsForUser(
        address user
    ) public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarAvailableForUser(currentId, user)) {
                itemCount += 1;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarAvailableForUser(currentId, user)) {
                CarInfo storage currentItem = idToCarInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isCarOfUser(
        uint256 carId,
        address user
    ) private view returns (bool) {
        return _exists(carId) && (ownerOf(carId) == user);
    }

    function getCarsOwnedByUser(
        address user
    ) public view returns (CarInfo[] memory) {
        if (!userService.isHost(user)) return new CarInfo[](0);

        uint itemCount = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarOfUser(currentId, user)) {
                itemCount += 1;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isCarOfUser(currentId, user)) {
                CarInfo storage currentItem = idToCarInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }

    function isRentedByUser(
        uint256 carId,
        address user
    ) private view returns (bool) {
        return _exists(carId) && userOf(carId) == user;
    }

    function getCarsRentedByUser(
        address user
    ) public view returns (CarInfo[] memory) {
        uint itemCount = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isRentedByUser(currentId, user)) {
                itemCount += 1;
            }
        }

        CarInfo[] memory result = new CarInfo[](itemCount);
        uint currentIndex = 0;

        for (uint i = 0; i < totalSupply(); i++) {
            uint currentId = i + 1;
            if (isRentedByUser(currentId, user)) {
                CarInfo storage currentItem = idToCarInfo[currentId];
                result[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }

        return result;
    }
}
