<script>
  import { selectedChain } from "./stores.js";
  import * as chains from "viem/chains";

  let supportedChains = [chains.hardhat, chains.mainnet, chains.goerli];
  let selectedChainIndex = 0;

  $: $selectedChain = supportedChains[selectedChainIndex];
</script>

<label>
  <span class="mr-2">Chain:</span>
  <select
    name="chain"
    bind:value={selectedChainIndex}
    class="p-2 border bg-purple-400 text-white rounded hover:bg-purple-300"
  >
    {#each supportedChains as chain, i}
      <option value={i}>{chain.name}</option>
    {/each}
  </select>
</label>
