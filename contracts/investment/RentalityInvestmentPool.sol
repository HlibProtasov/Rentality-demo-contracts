// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../Schemas.sol';
import '../proxy/UUPSAccess.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import "./RentalityInvestmentNft.sol";


contract RentalityCarInvestmentPool {
    IRentalityAccessControl private userService;
    RentalityInvestmentNft immutable private nft;
    uint immutable private investmentID;
    uint immutable private totalPriceInEth;

    uint[] private incomes;

    mapping(uint => uint) private nftIdToLastIncomeNumber;

    constructor(uint _investmentId, address _nft, uint totalPrice, address _userService) {
        nft = RentalityInvestmentNft(_nft);
        investmentID = _investmentId;
        totalPriceInEth = totalPrice;
        userService = IRentalityAccessControl(_userService);
    }
    function deposit() public payable {
        incomes.push(msg.value);
    }

    function claimAllMy() public {
        require(incomes.length > 0, "no incomes");
        (uint[] memory tokens, uint totalPriceOfMyTokens) = nft.getAllMyTokensWithTotalPrice();
        uint toClaim = 0;
        for (uint i = 0; i < tokens.length; i++) {
            uint lastIncomeClaimed = nftIdToLastIncomeNumber[tokens[i]];
            if (incomes.length > lastIncomeClaimed) {
                for (uint i = lastIncomeClaimed - 1; i < incomes.length; i++) {
                    toClaim += incomes[i];
                }
                nftIdToLastIncomeNumber[tokens[i]] = incomes[incomes.length];
            }
        }
        uint part = (totalPriceOfMyTokens * 100_000) / totalPriceInEth;
        uint result = (toClaim * part) / 100_000;

        if (result > 0) {
            (bool successRefund,) = payable(tx.origin).call{value: result}('');
            require(successRefund, 'payment failed.');

        }
    }

    function claim(uint tokenId) public {
        require(nft.ownerOf(tokenId) == tx.origin, "only Owner");
        require(incomes.length > 0, "no incomes");

        uint lastIncomeClaimed = nftIdToLastIncomeNumber[tokenId];
        require(incomes.length <= lastIncomeClaimed, "income claimed");

        uint price = nft.tokenIdToPriceInEth(tokenId);
        uint part = (price * 100_000) / totalPriceInEth;
        uint totalAmount = 0;
        for (uint i = lastIncomeClaimed - 1; i < incomes.length; i++) {
            totalAmount += incomes[i];
        }
        uint result = (totalAmount * part) / 100_000;
        if (result > 0) {
            (bool successRefund,) = payable(tx.origin).call{value: result}('');
            require(successRefund, 'payment failed.');

        }


    }

    function getIncomesByNftId(uint id) public view returns (uint) {
        uint lastIncomeClaimed = nftIdToLastIncomeNumber[id];
        uint result = 0;
        for (uint i = lastIncomeClaimed; i < incomes.length; i++) {
            result += incomes[i];
        }
        return result;
    }

    function getTotalIncome() public view returns (uint) {
        uint result = 0;
        for (uint i = 0; i < incomes.length; i++) {
            result += incomes[i];
        }
        return result;
    }

}
