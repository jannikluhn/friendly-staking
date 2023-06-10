/** @type {import('./$types').PageLoad} */
export function load({ params }) {
  return {
    chain: params.chain,
    index: params.index,
  };
}
