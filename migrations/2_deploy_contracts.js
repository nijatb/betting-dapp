var ECMath = artifacts.require("./ECMath.sol");
var JsmnSolLib = artifacts.require("jsmnsol-lib/JsmnSolLib.sol");
var FootballBetting = artifacts.require("./FootballBetting.sol");
var tlsnutils = artifacts.require("tlsnutils.sol");
var bytesutils = artifacts.require("bytesutils.sol");


module.exports = function(deployer, network) {
  if(network == "development"){
    deployer.deploy(JsmnSolLib);
    deployer.deploy(ECMath);
    deployer.deploy(bytesutils);
    deployer.link(ECMath,tlsnutils);
    deployer.link(bytesutils,tlsnutils);
    deployer.deploy(tlsnutils);
    deployer.link(JsmnSolLib, FootballBetting);
    deployer.link(tlsnutils, FootballBetting);
    deployer.deploy(FootballBetting);
  } else if(network == "rinkeby"){
    deployer.deploy(JsmnSolLib);
    deployer.deploy(ECMath);
    deployer.deploy(bytesutils);
    deployer.link(ECMath,tlsnutils);
    deployer.link(bytesutils,tlsnutils);
    deployer.deploy(tlsnutils);
    deployer.link(tlsnutils, FootballBetting);
    deployer.link(JsmnSolLib, FootballBetting);
    deployer.deploy(FootballBetting);
  }
};
