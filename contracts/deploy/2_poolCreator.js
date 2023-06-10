module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const fakeDepositContractDeployment = await deployments.get(
    "FakeDepositContract"
  );

  await deploy("PoolCreator", {
    from: deployer,
    gasLimit: 4000000,
    args: [fakeDepositContractDeployment.address],
  });
};
