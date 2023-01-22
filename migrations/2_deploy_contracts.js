const stake = artifacts.require("ApeStaking");
const ape = artifacts.require("TheApeProject")
//const BUSD = artifacts.require("BUSD")

module.exports = async function(deployer) {
  //deploy Token

  await deployer.deploy(ape)
  const LS1 = await ape.deployed()
  
  const varibleAddress = "0xAD93D504631feCA691d0a6EFed72f8344Ee72925";
  await deployer.deploy(stake, LS1.address, varibleAddress)
};