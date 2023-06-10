<script>
  export let value;
  export let placeholder = "";
  export let disabled = false;
</script>

<input
  type="text"
  {placeholder}
  class="w-full h-10 border border-black rounded px-1"
  class:cursor-not-allowed={disabled}
  bind:value
  {disabled}
/>
