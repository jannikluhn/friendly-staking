<script>
  export let friend;
</script>

<div class="flex">
  <div class="flex-1">
    <input type="text" placeholder="Address" class="w-full" bind:value={friend.address} disabled />
  </div>
  <div>
    <input type="text" placeholder="Share" bind:value={friend.share} disabled />
  </div>
  <div>
    <p>Deposited? {friend.deposited ? "yes" : "no"}</p>
  </div>
</div>
