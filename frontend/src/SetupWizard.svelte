<script>
  import { goto } from "$app/navigation";
  import { parseEther, decodeEventLog, isAddressEqual, isAddress } from "viem";

  import WalletConnectionButton from "./WalletConnectionButton.svelte";
  import ChainSelector from "./ChainSelector.svelte";
  import FriendSelector from "./FriendSelector.svelte";
  import Button from "./Button.svelte";

  import {
    requiresWalletConnection,
    poolCreatorDeployment,
    publicClient,
    walletClient,
    walletAccount,
    selectedChain,
  } from "./stores.js";

  let friends = [];
  let waiting = false;

  $: missingFields = !friends.every((f) => f.address !== "" && f.share !== "");
  $: invalidAddress = !friends.every((f) => isAddress(f.address));
  $: invalidShare = !friends.every((f) => {
    try {
      const v = parseEther(f.share);
      return v > 0;
    } catch {
      return false;
    }
  });
  $: shareSum = invalidShare
    ? null
    : friends.map((f) => parseEther(f.share)).reduce((a, b) => a + b, 0n);
  $: invalidShareSum = !invalidShare && shareSum != parseEther("32");
  $: notEnoughParticipants = friends.length <= 1;
  $: duplicateAddresses = new Set(friends.map((f) => f.address)).size !== friends.length;
  $: firstAddressNotWallet =
    !missingFields &&
    !invalidAddress &&
    $walletAccount &&
    friends.length > 1 &&
    !isAddressEqual(friends[0].address, $walletAccount);

  $: anyError = ![
    missingFields,
    invalidAddress,
    invalidShare,
    invalidShareSum,
    notEnoughParticipants,
    duplicateAddresses,
    firstAddressNotWallet,
  ].every((v) => !v);

  async function setup() {
    waiting = true;
    const addresses = friends.map((f) => f.address);
    const shares = friends.map((f) => parseEther(f.share));
    await $walletClient.switchChain({ id: $selectedChain.id });
    const { request } = await $publicClient.simulateContract({
      ...$poolCreatorDeployment,
      functionName: "setupPool",
      account: $walletAccount,
      args: [addresses, shares],
      value: shares[0],
    });
    const txHash = await $walletClient.writeContract(request);
    const receipt = await $publicClient.waitForTransactionReceipt({
      hash: txHash,
    });
    const log = receipt.logs[receipt.logs.length - 1];
    const ev = decodeEventLog({
      abi: $poolCreatorDeployment.abi,
      data: log.data,
      topics: log.topics,
    });

    console.log("pool created successfully, index", ev.args.index);
    waiting = false;
    goto(`/pool/${$selectedChain.name.toLowerCase()}/${ev.args.index.toString()}`);
  }
</script>

<p class="mb-4">
  This step will setup a new pool and define which addresses participate and which share each of
  them has. It will also automatically deploy a contract that will later split the rewards. Note
  that the friend who carries out this step will later be responsible to run the physical staking
  node.
</p>

<div>
  <WalletConnectionButton />
</div>

{#if !$requiresWalletConnection}
  <div class="mb-3">
    <ChainSelector />
  </div>

  <FriendSelector bind:friends />

  <div class="mt-8 mb-2">
    {#if missingFields}
      <p>Some fields are empty. Please fill out all of them to continue.</p>
    {:else if invalidAddress}
      <p>At least one address is invalid. Please correct it to continue.</p>
    {:else if invalidShare}
      <p>At least one share is invalid. Please make sure they are valid positive ETH values.</p>
    {:else if invalidShareSum}
      <p>The shares do not sum to the correct value. Please make sure they are 32 ETH in total.</p>
    {:else if notEnoughParticipants}
      <p>There are not enough participants. Make sure there are at least two.</p>
    {:else if duplicateAddresses}
      <p>At least one address appears twice. Make sure all participants have unique addresses.</p>
    {:else if firstAddressNotWallet}
      <p>
        The first address does not appear to belong to you. Please make sure it is yours and that it
        is selected in your wallet.
      </p>
    {/if}

    {#if !anyError}
      <p>All looks good. Press "Setup" below to create the pool!</p>
      <p />{/if}
  </div>

  <div class="m-2">
    <Button on:click={setup} disabled={anyError} {waiting}>Setup</Button>
  </div>
  <p />
{/if}
