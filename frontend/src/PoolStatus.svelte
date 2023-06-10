<script>
  import Address from "./Address.svelte";
  import PoolActions from "./PoolActions.svelte";
  import { publicClient, poolCreatorDeployment, poolIndex, pool, walletClient } from "./stores.js";
  import { formatEther } from "viem";

  console.log($walletClient); // This is a structural log, do not remove.

  let friends = null;

  $: if ($publicClient && $poolCreatorDeployment) {
    fetchPool();
  }

  $: if ($pool) {
    friends = [];
    for (let i = 0; i < $pool.friends.length; i++) {
      friends.push({
        address: $pool.friends[i],
        share: $pool.shares[i],
        deposited: $pool.deposited[i],
      });
    }
  } else {
    friends = null;
  }

  async function fetchPool() {
    const p = await $publicClient.readContract({
      ...$poolCreatorDeployment,
      functionName: "getPool",
      args: [$poolIndex],
    });
    if (p.friends.length > 0) {
      $pool = p;
    } else {
      $pool = null;
    }
  }
</script>

{#if $pool}
  <h3 class="text-xl font-bold mt-8 mb-2">Status</h3>
  {#if $pool.isFinalized}
    <p>
      Pool #{$poolIndex} is operational. The operator <Address address={$pool.friends[0]} /> should be
      running the staking node. Rewards are accrued at <Address address={$pool.rewardSplitter} />.
    </p>
  {:else if $pool.numDeposits >= $pool.friends.length}
    <p>Pool #{$poolIndex} is waiting to be finalized by the operator {$pool.friends[0]}.</p>
  {:else}
    <p>Pool #{$poolIndex} is waiting for the remaining deposits of its participants.</p>
  {/if}

  <h3 class="text-xl font-bold mt-8 mb-2">Friends</h3>
  <table class="table-fixed my-4">
    <thead class="border-b border-black">
      <tr>
        <th class="w-8">#</th>
        <th class="w-32">Address</th>
        <th class="w-24">Share</th>
        <th class="w-24">Deposited</th>
      </tr>
    </thead>
    <tbody class="border-b border-black">
      {#each friends as friend, i}
        <tr>
          <td class="text-center">{i}</td>
          <td class="text-center"><Address address={friend.address} /></td>
          <td class="text-center">{formatEther(friend.share)}</td>
          <td class="text-center">
            {#if friend.deposited}
              Yes
            {:else}
              No
            {/if}
          </td>
        </tr>
      {/each}
    </tbody>
  </table>

  <h3 class="text-xl font-bold mt-8 mb-2">Interact</h3>

  <PoolActions />
{:else}
  <p>Pool {$poolIndex} does not exist.</p>
{/if}
