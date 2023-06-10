<script>
  export let disabled = false;
  export let waiting = false;
</script>

<button
  on:click
  {disabled}
  class="p-2 rounded bg-purple-400 text-white font-bold"
  class:hover:bg-purple-300={!waiting && !disabled}
  class:cursor-not-allowed={disabled || waiting}
  class:bg-purple-200={disabled}
>
  <div class="relative">
    <div class:invisible={waiting}>
      <slot />
    </div>
    <div
      class="absolute left-0 top-0 w-full h-full flex flex-col justify-center"
      class:invisible={!waiting}
    >
      <svg
        class="animate-spin h-5 w-5 text-white mx-auto"
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
      >
        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
        <path
          class="opacity-75"
          fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        />
      </svg>
    </div>
  </div>
</button>
