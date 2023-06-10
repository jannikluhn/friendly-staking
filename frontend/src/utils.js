import { concat } from "viem";

export function computeWithdrawalCredentials(withdrawalAddress) {
  return concat(["0x01", "0x0000000000000000000000", withdrawalAddress]);
}
