const {ethers} = require("hardhat");

async function main() {
    const Pharma = await ethers.getContractFactory("Pharma");
    const pharma = await Pharma.deploy();
  
    console.log("Pharma address:", pharma.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });