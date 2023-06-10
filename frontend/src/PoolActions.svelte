<script>
  import { page } from "$app/stores";
  import { invalidate } from "$app/navigation";
  import { formatEther } from "viem";
  import Button from "./Button.svelte";
  import Input from "./Input.svelte";
  import Address from "./Address.svelte";
  import WalletConnectionButton from "./WalletConnectionButton.svelte";
  import {
    requiresWalletConnection,
    isFriend,
    deposited,
    poolIndex,
    pool,
    isFirstFriend,
    walletClient,
    selectedChain,
    poolCreatorDeployment,
    publicClient,
    walletAccount,
    friendIndex,
    share,
  } from "./stores";
  import { computeWithdrawalCredentials } from "./utils";

  let waitingForDeposit = false;
  let waitingForFinalization = false;

  let pubkey = "0x";
  let signature = "0x";
  let depositDataRoot = "0x0000000000000000000000000000000000000000000000000000000000000000";

  $: depositEnabled = $isFriend && !$deposited;
  $: finalizeEnabled =
    $isFirstFriend && !$pool.isFinalized && $pool.numDeposited >= $pool.friends.length;
  $: withdrawalCredentials = $pool ? computeWithdrawalCredentials($pool.rewardSplitter) : null;

  async function deposit() {
    waitingForDeposit = true;
    await $walletClient.switchChain({ id: $selectedChain.id });
    const { request } = await $publicClient.simulateContract({
      ...$poolCreatorDeployment,
      functionName: "deposit",
      account: $walletAccount,
      args: [$poolIndex, $friendIndex],
      value: $share,
    });
    const txHash = await $walletClient.writeContract(request);
    const receipt = await $publicClient.waitForTransactionReceipt({
      hash: txHash,
    });
    console.log(receipt);
    waitingForDeposit = false;
    await invalidate($page.path);
  }

  async function finalize() {
    waitingForFinalization = true;
    await $walletClient.switchChain({ id: $selectedChain.id });
    const { request } = await $publicClient.simulateContract({
      ...$poolCreatorDeployment,
      functionName: "finalizePool",
      account: $walletAccount,
      args: [$poolIndex, pubkey, signature, depositDataRoot],
    });
    const txHash = await $walletClient.writeContract(request);
    const receipt = await $publicClient.waitForTransactionReceipt({
      hash: txHash,
    });
    console.log(receipt);
    waitingForFinalization = false;
    await invalidate($page.path);
  }
</script>

<div>
  {#if $pool.isFinalized}
    <p>The pool is already operational and no interactions are necessary. Happy staking!</p>
  {:else if $requiresWalletConnection}
    <p>Please connect your wallet in order to interact with the pool.</p>
    <WalletConnectionButton />
  {:else if !$isFriend}
    <p>
      Your address is <Address address={$walletAccount} />. You don't seem to be a friend of this
      pool and can therefore cannot interact with it.
    </p>
  {:else}
    {#if !$deposited}
      <p>
        Your address is <Address address={$walletAccount} /> and you're a friend of this pool! Your share
        is {formatEther($share)} ETH which you have not yet deposited. Click the button below to do so
        now.
      </p>
    {:else}
      <p>
        Your address is <Address address={$walletAccount} /> and you're a friend of this pool! Your share
        is {formatEther($share)} ETH which you have already deposited. You're good.
      </p>
    {/if}
    <div class="m-2">
      <Button disabled={!depositEnabled} on:click={deposit} waiting={waitingForDeposit}>
        Deposit
      </Button>
    </div>

    {#if $isFirstFriend}
      {#if $pool.numDeposited < $pool.friends.length}
        <p class="mt-4">
          You're the operator of the pool. Once your friends have deposited their share, you will be
          able to finalize the pool and start staking!
        </p>
      {:else}
        <p class="mt-4">
          You're the operator of the pool and it is ready to be finalized. Generate the deposit data
          consisting of pubkey, signature, and deposit data root with a tool of your choice and
          enter it in the form below. Be sure to use withdrawal credentials
          <span class="font-mono">{withdrawalCredentials}</span>! To conclude, press the button
          below and start staking!
        </p>
      {/if}
      <table class="table-auto w-full my-4">
        <tbody>
          <tr>
            <td class="w-48 text-right pr-2">Pubkey</td>
            <td>
              <Input placeholder="Pubkey" bind:value={pubkey} disabled={!finalizeEnabled} />
            </td>
          </tr>
          <tr>
            <td class="text-right pr-2">Signature</td>
            <td>
              <Input placeholder="Pubkey" bind:value={pubkey} disabled={!finalizeEnabled} />
            </td>
          </tr>
          <tr>
            <td class="text-right pr-2">Deposit Data Root</td>
            <td>
              <Input placeholder="Pubkey" bind:value={pubkey} disabled={!finalizeEnabled} />
            </td>
          </tr>
        </tbody>
      </table>

      <div class="m-2">
        <Button disabled={!finalizeEnabled} on:click={finalize} waiting={waitingForFinalization}>
          Finalize
        </Button>
      </div>
    {/if}
  {/if}
</div>
