<script>
  import * as chains from "viem/chains";
  import PoolStatus from "../../../../PoolStatus.svelte";
  import { selectedChain, poolIndex } from "../../../../stores.js";
  import SubHeading from "../../../../SubHeading.svelte";

  export let data;

  $: {
    $selectedChain = null;
    for (const [key, value] of Object.entries(chains)) {
      if (value.network === data.chain) {
        $selectedChain = value;
      }
    }
  }
  $: $poolIndex = parseInt(data.index);
</script>

<SubHeading>Pool #{$poolIndex}</SubHeading>
<PoolStatus />
