module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const tokenDeployment = await deploy("SBCToken", {
    from: deployer,
    gasLimit: 4000000,
    args: [],
  });
  const depositContractDeployment = await deploy("SBCDepositContract", {
    from: deployer,
    gasLimit: 4000000,
    args: [tokenDeployment.address],
  });
  await deploy("PoolCreatorERC20", {
    from: deployer,
    gasLimit: 4000000,
    args: [depositContractDeployment.address],
  });
};
