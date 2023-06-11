require("dotenv").config();

require("@nomicfoundation/hardhat-ethers");
require("hardhat-deploy");

const {
  GOERLI_RPC_URL,
  GOERLI_PRIVATE_KEY,
  CHIADO_RPC_URL,
  CHIADO_PRIVATE_KEY,
} = process.env;

const DEPOSIT_PUBKEY =
  "0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
const DEPOSIT_SIGNATURE =
  "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
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
        version: "0.8.9",
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
    chiado: {
      url: CHIADO_RPC_URL,
      accounts: [CHIADO_PRIVATE_KEY],
    },
  },
  namedAccounts: {
    deployer: {
      hardhat: 0,
      goerli: 0,
      chiado: 0,
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
    .finalizePool(
      poolIndex,
      DEPOSIT_PUBKEY,
      DEPOSIT_SIGNATURE,
      DEPOSIT_DATA_ROOT
    );
  const finalizeReceipt = await finalizeTx.wait();

  const pool = await poolCreator.connect(signers[0]).getPool(poolIndex);
  console.log(pool);

  console.log("Done.");
});

task("test-erc20", "Test ERC20", async (taskArgs, hre) => {
  const signers = await hre.ethers.getSigners();
  const poolCreatorDeployment = await hre.deployments.get("PoolCreatorERC20");
  const poolCreator = new hre.ethers.Contract(
    poolCreatorDeployment.address,
    poolCreatorDeployment.abi
  );
  const tokenDeployment = await hre.deployments.get("SBCToken");
  const token = new hre.ethers.Contract(
    tokenDeployment.address,
    tokenDeployment.abi
  );

  console.log("Setting up pool...");
  const addresses = [signers[0].address, signers[1].address];
  const amounts = [hre.ethers.parseEther("0.8"), hre.ethers.parseEther("0.2")];
  const abiCoder = new hre.ethers.AbiCoder();
  const setupArgs = abiCoder.encode(
    ["address[]", "uint256[]"],
    [addresses, amounts]
  );
  const setupCallBytes = "0x00" + setupArgs.slice(2);
  const setupTx = await token
    .connect(signers[0])
    .transferAndCall(poolCreatorDeployment.address, amounts[0], setupCallBytes);
  console.log(setupTx);
  const setupReceipt = await setupTx.wait();
  const setupLog = setupReceipt.logs[setupReceipt.logs.length - 1];
  const setupEvent = poolCreator.interface.parseLog(setupLog);
  const poolIndex = setupEvent.args[0];
  const rewardAddress = setupEvent.args[1];

  console.log("Depositing...");
  await token.connect(signers[0]).transfer(addresses[1], amounts[1]);
  const depositArgs = abiCoder.encode(["uint256", "uint256"], [poolIndex, 1]);
  const depositCallBytes = "0x01" + depositArgs.slice(2);
  const depositTx = await token
    .connect(signers[1])
    .transferAndCall(
      poolCreatorDeployment.address,
      amounts[1],
      depositCallBytes
    );
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

task("fund-erc20", "")
  .addParam("account", "The account to fund")
  .setAction(async (taskArgs, hre) => {
    const signers = await hre.ethers.getSigners();
    const tokenDeployment = await hre.deployments.get("SBCToken");
    const token = new hre.ethers.Contract(
      tokenDeployment.address,
      tokenDeployment.abi
    );
    const currentBalance = await token
      .connect(signers[0])
      .balanceOf(taskArgs.account);
    console.log("balance before:", ethers.formatUnits(currentBalance, "ether"));
    await token
      .connect(signers[0])
      .transfer(taskArgs.account, ethers.parseEther("1024"), {
        gasPrice: 2000000000,
      });
    await signers[0].sendTransaction({
      to: taskArgs.account,
      value: ethers.parseEther("0.1"),
      gasPrice: 2000000000,
    });
  });
