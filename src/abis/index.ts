import RentalityGatewayJSON_ABI from "./investment/RentalityGateway.v0_2_0.abi.json";
import RentalityGatewayJSON_ADDRESSES from "./investment/RentalityGateway.v0_2_0.addresses.json";
import RentalityAdminGatewayJSON_ABI from "./investment/RentalityAdminGateway.v0_2_0.abi.json";
import RentalityAdminGatewayJSON_ADDRESSES from "./investment/RentalityAdminGateway.v0_2_0.addresses.json";
import RentalityInvestServiceJSON_ADDRESSES from "./investment/RentalityInvestment.v0_2_0.addresses.json";
import RentalityInvestServiceJSON_ABI from "./investment/RentalityInvestment.v0_2_0.abi.json";
import RentalityLocationVerifierJSON_ADDRESSES from "./investment/RentalityLocationVerifier.v0_2_0.addresses.json";
import RentalityLocationVerifierJSON_ABI from "./investment/RentalityLocationVerifier.v0_2_0.abi.json";
import RentalityNotificationServiceJSON_ADDRESSES from "./investment/RentalityNotificationService.v0_2_0.addresses.json";
import RentalityNotificationServiceJSON_ABI from "./investment/RentalityNotificationService.v0_2_0.abi.json";
import RentalityCurrencyConverterJSON_ADDRESSES from "./investment/RentalityCurrencyConverter.v0_2_0.addresses.json";
import RentalityCurrencyConverterJSON_ABI from "./investment/RentalityCurrencyConverter.v0_2_0.abi.json";

import RentalityRefferalProgramServiceJSON_ABI from "./investment/RentalityReferralProgram.v0_2_0.abi.json";
import RentalityRefferalProgramServiceJSON_ADDRESSES from "./investment/RentalityReferralProgram.v0_2_0.addresses.json";
import { Contract, Signer } from "ethers";
import { getExistBlockchainList } from "@/model/blockchain/blockchainList";

export const SMARTCONTRACT_VERSION = "v0_2_0";

const rentalityContracts = {
  gateway: {
    addresses: RentalityGatewayJSON_ADDRESSES.addresses,
    abi: RentalityGatewayJSON_ABI.abi,
  },
  admin: {
    addresses: RentalityAdminGatewayJSON_ADDRESSES.addresses,
    abi: RentalityAdminGatewayJSON_ABI.abi,
  },
  notificationService: {
    addresses: RentalityNotificationServiceJSON_ADDRESSES.addresses,
    abi: RentalityNotificationServiceJSON_ABI.abi,
  },
  verifierService: {
    addresses: RentalityLocationVerifierJSON_ADDRESSES.addresses,
    abi: RentalityLocationVerifierJSON_ABI.abi,
  },
  investService: {
    addresses: RentalityInvestServiceJSON_ADDRESSES.addresses,
    abi: RentalityInvestServiceJSON_ABI.abi,
  },
  currencyConverter: {
    addresses: RentalityCurrencyConverterJSON_ADDRESSES.addresses,
    abi: RentalityCurrencyConverterJSON_ABI.abi,
  },
  refferalPogram: {
    addresses: RentalityRefferalProgramServiceJSON_ADDRESSES.addresses,
    abi: RentalityRefferalProgramServiceJSON_ABI.abi,
  },
};

export async function getEtherContractWithSigner(contract: keyof typeof rentalityContracts, signer: Signer) {
  try {
    if (!signer) {
      console.error("getEtherContract error: signer is null");
      return null;
    }

    const chainId = Number((await signer.provider?.getNetwork())?.chainId);
    if (!getExistBlockchainList().find((i) => i.chainId === chainId)) {
      console.error(`getEtherContract error: Chain id ${chainId} is not supported`);
      return null;
    }

    const selectedChain = rentalityContracts[contract].addresses.find((i) => i.chainId === chainId);

    if (!selectedChain) {
      console.error(`getEtherContract error: ${contract} address for chainId ${chainId} is not found`);
      return null;
    }
    const etherContract = new Contract(selectedChain.address, rentalityContracts[contract].abi, signer);
    return etherContract;
  } catch (e) {
    console.error("getEtherContract error:" + e);
    return null;
  }
}

export function hasContractForChainId(chainId: number) {
  return rentalityContracts.gateway.addresses.find((i) => i.chainId === chainId) !== undefined;
}

export function getContractAddress(contract: keyof typeof rentalityContracts, chainId: number) {
  try {
    if (!getExistBlockchainList().find((i) => i.chainId === chainId)) {
      console.error(`getEtherContract error: Chain id ${chainId} is not supported`);
      return null;
    }

    const selectedChain = rentalityContracts[contract].addresses.find((i) => i.chainId === chainId);

    if (!selectedChain) {
      console.error(`getEtherContract error: ${contract} address for chainId ${chainId} is not found`);
      return null;
    }
    return selectedChain.address;
  } catch (e) {
    console.error("get address error error:" + e);
    return null;
  }
}

export default rentalityContracts;
