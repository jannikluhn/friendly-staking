<script>
  import * as chains from "viem/chains";
  import PoolStatus from "../../../../PoolStatus.svelte";
  import { selectedChain, poolIndex } from "../../../../stores.js";
  import SubHeading from "../../../../SubHeading.svelte";

  export let data;

  $: $selectedChain = chains[data.chain];
  $: $poolIndex = parseInt(data.index);
</script>

<SubHeading>Pool #{$poolIndex}</SubHeading>
<PoolStatus />
