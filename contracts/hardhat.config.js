require("dotenv").config();

require("@nomicfoundation/hardhat-ethers");
require("hardhat-deploy");

const { GOERLI_RPC_URL, GOERLI_PRIVATE_KEY } = process.env;

const DEPOSIT_DATA_ROOT =
  "0x0000000000000000000000000000000000000000000000000000000000000000";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.11",
      },
    ],
  },
  paths: {
    sources: "./src",
  },
  networks: {
    hardhat: {},
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: [GOERLI_PRIVATE_KEY],
    },
  },
  namedAccounts: {
    deployer: {
      hardhat: 0,
      goerli: 0,
    },
  },
};

task("test", "Test", async (taskArgs, hre) => {
  const signers = await hre.ethers.getSigners();
  const poolCreatorDeployment = await hre.deployments.get("PoolCreator");
  const poolCreator = new hre.ethers.Contract(
    poolCreatorDeployment.address,
    poolCreatorDeployment.abi
  );

  const addresses = [signers[0].address, signers[1].address];
  const amounts = [hre.ethers.parseEther("20"), hre.ethers.parseEther("12")];

  console.log("Setting up pool...");
  const setupTx = await poolCreator
    .connect(signers[0])
    .setupPool(addresses, amounts, { value: amounts[0] });
  const setupReceipt = await setupTx.wait();
  const poolIndex = setupReceipt.logs[2].args[0];
  const rewardAddress = setupReceipt.logs[2].args[1];

  console.log("Depositing...");
  const depositTx = await poolCreator
    .connect(signers[1])
    .deposit(poolIndex, 1, { value: amounts[1] });
  const depositReceipt = await depositTx.wait();

  console.log("Finalizing...");
  const finalizeTx = await poolCreator
    .connect(signers[0])
    .finalizePool(poolIndex, "0x", "0x", DEPOSIT_DATA_ROOT);
  const finalizeReceipt = await finalizeTx.wait();

  const pool = await poolCreator.connect(signers[0]).getPool(poolIndex);
  console.log(pool);

  console.log("Done.");
});

task("rugpull", "Withdraw (stuck) ETH", async (taskArgs, hre) => {
  const signers = await hre.ethers.getSigners();
  const poolCreatorDeployment = await hre.deployments.get("PoolCreator");
  const poolCreator = new hre.ethers.Contract(
    poolCreatorDeployment.address,
    poolCreatorDeployment.abi
  );
  const fakeDepositContractDeployment = await hre.deployments.get(
    "FakeDepositContract"
  );
  const fakeDepositContract = new hre.ethers.Contract(
    fakeDepositContractDeployment.address,
    fakeDepositContractDeployment.abi
  );

  const balanceBefore = await ethers.provider.getBalance(signers[0].address);
  console.log("balance before:", ethers.formatUnits(balanceBefore, "ether"));
  await poolCreator.connect(signers[0]).rugpull();
  await fakeDepositContract.connect(signers[0]).rugpull();
  const balanceAfter = await ethers.provider.getBalance(signers[0].address);
  console.log("balance after:", ethers.formatUnits(balanceAfter, "ether"));
});
