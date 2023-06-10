import poolCreatorGoerli from "./deployments/goerli/PoolCreator.json";
import poolCreatorLocalhost from "./deployments/localhost/PoolCreator.json";

const poolCreatorDeployments = {
  5: poolCreatorGoerli,
  31337: poolCreatorLocalhost,
};

export { poolCreatorDeployments };
