import poolCreatorGoerli from "./deployments/goerli/PoolCreator.json";

// import poolCreatorLocalhost from "./deployments/localhost/PoolCreator.json";
import poolCreatorERC20Localhost from "./deployments/localhost/PoolCreatorERC20.json";
import sbcTokenLocalhost from "./deployments/localhost/SBCToken.json";

import poolCreatorERC20Chiado from "./deployments/chiado/PoolCreatorERC20.json";
import sbcTokenChiado from "./deployments/chiado/SBCToken.json";

const poolCreatorDeployments = {
  5: poolCreatorGoerli,
  10200: poolCreatorERC20Chiado,
  31337: poolCreatorERC20Localhost,
};

const tokenDeployments = {
  10200: sbcTokenChiado,
  31337: sbcTokenLocalhost,
};

const isERC20Deployment = {
  5: false,
  10200: true,
  31337: true,
};

export { poolCreatorDeployments, tokenDeployments, isERC20Deployment };
