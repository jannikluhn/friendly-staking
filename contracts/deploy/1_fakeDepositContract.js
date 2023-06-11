module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("FakeDepositContract", {
    from: deployer,
    gasLimit: 4000000,
    gasPrice: 10000000000,
    args: [],
  });
};
