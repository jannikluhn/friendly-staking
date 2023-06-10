<script>
  import { createEventDispatcher } from "svelte";
  import Button from "./Button.svelte";
  import Input from "./Input.svelte";

  export let address;
  export let share;

  const dispatch = createEventDispatcher();

  function remove() {
    dispatch("remove");
  }
</script>

<div class="flex gap-2 justify-center items-center">
  <div class="flex-1">
    <Input placeholder="address" bind:value={address} />
  </div>
  <div class="w-16">
    <Input placeholder="share" bind:value={share} />
  </div>
  <div>
    <Button on:click={remove}>Remove</Button>
  </div>
</div>
