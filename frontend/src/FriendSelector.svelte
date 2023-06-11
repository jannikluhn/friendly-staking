<script>
  import FriendLine from "./FriendLine.svelte";
  import Button from "./Button.svelte";
  import { walletAccount } from "./stores.js";

  export let friends = [];
  addFriend();
  addFriend();

  function addFriend() {
    const friend = {
      address: "",
      share: "",
    };
    friends = [...friends, friend];
  }

  function removeFriend(i) {
    friends = [...friends.slice(0, i), ...friends.slice(i + 1, friends.length)];
  }

  $: if ($walletAccount) {
    if (friends.length === 0) {
      addFriend();
    }
    if (friends[0].address === "") {
      friends[0].address = $walletAccount;
    }
  }
</script>

<div class="flex flex-col gap-2 mt-4 mb-2">
  {#each friends as friend, i}
    <FriendLine
      bind:address={friend.address}
      bind:share={friend.share}
      on:remove={() => removeFriend(i)}
    />
  {/each}
</div>

<Button on:click={addFriend}>Add Friend</Button>
