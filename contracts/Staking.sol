pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract Staking is Ownable{

IERC20 public cVToken;
uint256[10] public discounts;
uint256[10] public discountThreshold;
uint256 public stakingTime;

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

constructor(
  IERC20 _cVToken, uint256 _stakingTime)public{
    require(_cVToken != address(0));
    cVToken = _cVToken;
    stakingTime = _stakingTime;
  }

struct StakeInfo{

  uint256 unstakeTime;
  uint256 stakeAmount;

}

mapping(address => StakeInfo) StakeTable;

// Returns percentage of discount that staker will receive
function stakeOf(address staker)public view returns(uint256){
  return StakeTable[staker].stakeAmount;
}

function discountOf(address staker)public view returns(uint256){

  uint256 amount = stakeOf(staker);

  if(amount <  discountThreshold[0]){
    return 0;
  }
  else if(amount >=discountThreshold[0] && amount<discountThreshold[1]){
    return discounts[0];
  }
  else if(amount >= discountThreshold[1] && amount <discountThreshold[2]){
    return discounts[1];
  }
  else if(amount >= discountThreshold[2] && amount <discountThreshold[3]){
    return discounts[2];
  }
  else if(amount >= discountThreshold[3] && amount <discountThreshold[4]){
    return discounts[3];
  }
  else if(amount >= discountThreshold[4] && amount <discountThreshold[5]){
    return discounts[4];
  }
  else if(amount >= discountThreshold[5] && amount <discountThreshold[6]){
    return discounts[5];
  }
  else if(amount >= discountThreshold[6] && amount <discountThreshold[7]){
    return discounts[6];
  }
  else if(amount >= discountThreshold[7] && amount <discountThreshold[8]){
    return discounts[7];
  }
  else if(amount >= discountThreshold[8] && amount <discountThreshold[9]){
    return discounts[8];
  }
  else {
    return discounts[9];
  }

}

function stake(address staker, uint256 amount) onlyOwner{

  if(StakeTable[staker].stakeAmount == 0){
  StakeTable[staker].unstakeTime = stakingTime.add(now);
  StakeTable[staker].stakeAmount = amount;
  }
  else{ //FFR discuss second staking
    StakeTable[staker].stakeAmount = StakeTable[staker].stakeAmount.add(amount);
  }
}

function unstake(address staker) onlyOwner{

require(StakeTable[staker].unstakeTime <= now);
require(StakeTable[staker].stakeAmount > 0);

cVToken.safeTransfer(staker,StakeTable[staker].stakeAmount);

StakeTable[staker].stakeAmount = 0;
StakeTable[staker].unstakeTime = 0;
}

function setDiscount(uint256 _discountNr,uint256 _newDiscount)onlyOwner{
  require(_discountNr >= 1 && _discountNr <=10 );
  require(_newDiscount >=0 && _newDiscount<=100);
  _discountNr = _discountNr.sub(1);
  discounts[_discountNr] = _newDiscount;
}

function setThreshold(uint256 _thresholdNr,uint256 _newThreshold)public onlyOwner{
  require(_thresholdNr>= 1 && _thresholdNr<= 10);

  _thresholdNr = _thresholdNr.sub(1);
  discountThreshold[_thresholdNr] = _newThreshold;
}

function getAddress()returns(address){
  return address(this);
}

}
