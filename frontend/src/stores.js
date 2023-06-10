import { writable, derived } from "svelte/store";
import { createPublicClient, createWalletClient, custom, isAddressEqual } from "viem";
import * as chains from "viem/chains";
import { poolCreatorDeployments } from "./deployments.js";

export const windowStore = writable(null);

export const selectedChain = writable(chains.mainnet);

export const walletAccounts = writable([]);

export const connectedChain = writable(null);

export const publicClient = derived(
  [selectedChain, windowStore],
  ([$selectedChain, $windowStore]) => {
    if (!$windowStore) {
      return null;
    }
    return createPublicClient({
      chain: $selectedChain,
      transport: custom($windowStore.ethereum),
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
