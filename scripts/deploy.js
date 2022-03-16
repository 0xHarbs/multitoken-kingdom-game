const { ethers } = require("hardhat");
require("dotenv").config({ path: ".env" });

async function main() {
  const BattleContract = await ethers.getContractFactory("Battle");
  const deployedBattleContract = await BattleContract.deploy(BattleContract);
  console.log("Battle contract deployed to address:", deployedBattleContract.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
