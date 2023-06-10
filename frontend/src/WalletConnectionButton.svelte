<script>
  import Button from "./Button.svelte";
  import { walletClient, walletAccounts, requiresWalletConnection } from "./stores";

  async function connect() {
    $walletAccounts = await $walletClient.requestAddresses();
  }
</script>

{#if $requiresWalletConnection}
  <Button on:click={connect}>Connect</Button>
{/if}
