var CvToken = artifacts.require("./cVTokenOnly/cVToken.sol");
var StakeContract = artifacts.require("./Staking.sol");

var tokenAddressRinkeby = "0xAfff042F602762B59442660aCDF34fdE8681D016";
var tokenAddressMain = "0xdA6cb58A0D0C01610a29c5A65c303e13e885887C";

const discounts = [2,4,6,8,10,12,14,16,18,20];

module.exports = function(deployer) {
  if (deployer.network == 'development') {
    return deployer.deploy(CvToken).then(() => {
      return deployer.deploy(StakeContract,CvToken.address,100,100,3000, discounts);
    });
  } else if(deployer.network == 'rinkeby') {
    return deployer.deploy(StakeContract,tokenAddressRinkeby);
  } else{
    return deployer.deploy(BurnContract,tokenAddressMain);
  }
};
