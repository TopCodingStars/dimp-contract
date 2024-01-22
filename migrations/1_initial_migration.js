const DIMP = artifacts.require("DIMP");
const DIMPInternalExchange = artifacts.require("DIMPInternalExchange");
const DIMPSwap = artifacts.require("DIMPSwap");
const USDC = artifacts.require("USDC");
const fs = require("fs");

const whiltelistAddresses = [
  "0x47dD6Df8e066617b0eD5BEAC914eefe27Cf63978",
  "0xeaD7411f482223D0b4414845550A2163b571220c",
  "0xcdc7ccA7155faeD56027065Cde224836c9452237",
];

const whiltelistAmounts = [
  "39546534860000000",
  "79093069720000000",
  "118639604582000000",
];

module.exports = async function (deployer) {
  // await deployer.deploy(
  //   DIMP,
  //   whiltelistAddresses,
  //   whiltelistAmounts,
  //   "0x42E9226c29d10a58E4645A65Baa1Ae0d4E5D3a6C",
  //   "0x3F8C493dAD7e63CE88C78b6932101e21680BF355",
  //   "0x77049cabEcf13f432374270061955221b1268b1E",
  // );
  // const dimp = await DIMP.deployed();

  await deployer.deploy(DIMPInternalExchange, "0xecE1CD361F9eb015F9bcd407370a39BBb91f995E"); // dimp.address);
  const exchange = await DIMPInternalExchange.deployed();

  // await deployer.deploy(
  //   DIMPSwap,
  //   "0x1F98431c8aD98523631AE4a59f267346ea31F984",
  //   "0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45", // "0xE592427A0AEce92De3Edee1F18E0157C05861564",
  //   "0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6",
  //   "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889",
  // );
  // const swap = await DIMPSwap.deployed();

  // await deployer.deploy(USDC);

  // fs.writeFileSync(
  //   "./migrations/deployed.json",
  //   JSON.stringify({
  //     // DIMP: dimp.address,
  //     // DIMPInternalExchange: exchange.address,
  //     DIMPSwap: swap.address,
  //   }),
  // );
};
