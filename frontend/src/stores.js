import { writable, derived } from "svelte/store";
import {
  createPublicClient,
  createWalletClient,
  custom,
  isAddressEqual,
  parseEther,
  http,
} from "viem";
import * as chains from "viem/chains";
import { rpcs } from "./rpcs.js";
import { poolCreatorDeployments, isERC20Deployment, tokenDeployments } from "./deployments.js";

export const windowStore = writable(null);

export const selectedChain = writable(chains.goerli);

export const walletAccounts = writable([]);

export const connectedChain = writable(null);

export const publicTransport = derived(
  [selectedChain, windowStore],
  ([$selectedChain, $windowStore]) => {
    if (!$selectedChain) {
      return null;
    }
    if (rpcs[$selectedChain.id]) {
      return http(rpcs[$selectedChain.id]);
    } else {
      if (!$windowStore) {
        return null;
      } else {
        return custom($windowStore.ethereum);
      }
    }
  }
);

export const publicClient = derived(
  [selectedChain, publicTransport],
  ([$selectedChain, $publicTransport]) => {
    if (!$selectedChain || !$publicTransport) {
      return null;
    }
    return createPublicClient({
      chain: $selectedChain,
      transport: $publicTransport,
    });
  }
);

export const walletClient = derived(
  [selectedChain, windowStore],
  ([$selectedChain, $windowStore]) => {
    if (!$windowStore) {
      return null;
    }
    const client = createWalletClient({
      chain: $selectedChain,
      transport: custom($windowStore.ethereum),
    });
    client.getAddresses().then(walletAccounts.set);
    client.getChainId().then((chainID) => {
      for (const [name, chain] of Object.entries(chains)) {
        if (chain.id === chainID) {
          connectedChain.set(chain);
          return;
        }
      }
      connectedChain.set(null);
    });
    return client;
  }
);

export const walletAccount = derived(walletAccounts, ($walletAccounts) => {
  if (!$walletAccounts || $walletAccounts.length === 0) {
    return null;
  }
  return $walletAccounts[0];
});

export const requiresWalletConnection = derived(walletAccount, ($walletAccount) => {
  return !$walletAccount;
});

export const requiresChainSwitch = derived(
  [selectedChain, connectedChain],
  ([$selectedChain, $connectedChain]) => {
    if ($selectedChain === null || $connectedChain === null) {
      return true;
    }
    return $selectedChain.id !== $connectedChain.id;
  }
);

export const poolCreatorDeployment = derived(selectedChain, ($selectedChain) => {
  if (!$selectedChain) {
    return null;
  }
  return poolCreatorDeployments[$selectedChain.id] || null;
});

export const isERC20 = derived(selectedChain, ($selectedChain) => {
  if (!$selectedChain) {
    return null;
  }
  return isERC20Deployment[$selectedChain.id];
});

export const tokenDeployment = derived(selectedChain, ($selectedChain) => {
  if (!$selectedChain) {
    return null;
  }
  return tokenDeployments[$selectedChain.id] || null;
});

export const totalDepositAmount = derived(isERC20, ($isERC20) => {
  if ($isERC20) {
    return parseEther("1");
  } else {
    return parseEther("32");
  }
});

export const tokenSymbol = derived(isERC20, ($isERC20) => {
  if ($isERC20) {
    return "GNO";
  } else {
    return "ETH";
  }
});

export const poolIndex = writable(null);

export const pool = writable(null);

export const friendIndex = derived([pool, walletAccount], ([$pool, $walletAccount]) => {
  if (!$pool || !$walletAccount) {
    return null;
  }
  for (const [i, friend] of $pool.friends.entries()) {
    if (isAddressEqual(friend, $walletAccount)) {
      return i;
    }
  }
  return null;
});

export const isFriend = derived(friendIndex, ($friendIndex) => {
  return $friendIndex !== null;
});

export const deposited = derived([pool, friendIndex], ([$pool, $friendIndex]) => {
  if (!$pool || $friendIndex === null) {
    return null;
  }
  return $pool.deposited[$friendIndex];
});

export const share = derived([pool, friendIndex], ([$pool, $friendIndex]) => {
  if (!$pool || $friendIndex === null) {
    return null;
  }
  return $pool.shares[$friendIndex];
});

export const isFirstFriend = derived([pool, walletAccount], ([$pool, $walletAccount]) => {
  if (!$pool || !$walletAccount) {
    return null;
  }
  return isAddressEqual($walletAccount, $pool.friends[0]);
});
