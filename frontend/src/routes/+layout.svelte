<script>
  import { onMount } from "svelte";
  import { windowStore, walletAccounts } from "../stores.js";

  import "../app.css";

  onMount(() => {
    $windowStore = window;
    window.ethereum.on("accountsChanged", (accounts) => {
      $walletAccounts = accounts;
    });
  });
</script>

<div class="w-full min-h-screen bg-lime-100">
  <div class="container mx-auto max-w-screen-sm pb-8">
    <div class="h-32 flex flex-col justify-center">
      <h1 class="text-6xl font-bold text-center"><a href="/">Friendly Staking</a></h1>
    </div>

    <slot />
  </div>
</div>
