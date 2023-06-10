<script>
  export let address;
  $: addressShort = address.slice(0, 6) + ".." + address.slice(38, 42);
</script>

<span class="font-mono">{addressShort}</span>
