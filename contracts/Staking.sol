pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

//Set max and min discount and make it increase monotonically
contract Staking is Ownable{

IERC20 public cVToken;
uint256 public stakingTime;
uint256 public minThreshold;
uint256 public maxThreshold;
uint256 [10]discounts;

  using SafeMath for uint256;

constructor(
  IERC20 _cVToken,
  uint256 _stakingTime,
  uint256 _minThreshold,
  uint256 _maxThreshold)public{
    require(_cVToken != address(0));
    cVToken = _cVToken;
    stakingTime = _stakingTime;
    minThreshold = _minThreshold; //in wei
    maxThreshold = _maxThreshold; //in wei
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

function discountOf(address staker)public view returns(uint256){ //Change and rewrite with formulas

  uint256 stakedAmount = stakeOf(staker);

  if(stakedAmount >= maxThreshold) return discounts[0];
  if(stakedAmount < minThreshold) return 0;

  uint256 TEN = 10;
  uint256 numerator = stakedAmount.sub(minThreshold);
  uint256 denominator = maxThreshold.sub(minThreshold);

  uint256 discountIndex = uint256(TEN.mul(uint256(numerator.div(denominator))));

  return discounts[discountIndex];
}

function stake(uint256 amount){

  address staker = msg.sender;

  require(cVToken.transferFrom(staker,address(this),amount)); //Transfer in wei

  if(StakeTable[staker].stakeAmount == 0){
  StakeTable[staker].unstakeTime = stakingTime.add(now);
  StakeTable[staker].stakeAmount = amount; // in wei
  }
  else{ //FFR discuss second staking
    StakeTable[staker].stakeAmount = StakeTable[staker].stakeAmount.add(amount);
  }
}

function unstake(){
address staker = msg.sender;

require(StakeTable[staker].unstakeTime <= now);
require(StakeTable[staker].stakeAmount > 0);

cVToken.transfer(staker,StakeTable[staker].stakeAmount);

StakeTable[staker].stakeAmount = 0;
StakeTable[staker].unstakeTime = 0;
}

function setDiscounts(uint256 _minDiscount,uint256 _maxDiscount)onlyOwner{
  require(_minDiscount > 0);
  require(_maxDiscount < 100);
  require(_minDiscount < _maxDiscount);

  uint256 interval = _maxDiscount.sub(_minDiscount);

  uint256 period = interval.div(9);

  discounts[0] = _minDiscount;

  for(uint256 e=1; e<10; e++){
    discounts[e] = discounts[e-1].add(period);
  }
}

function setThresholds(uint256 _minThreshold ,uint256 _maxThreshold)public onlyOwner{
  require(_minThreshold < _maxThreshold);

  minThreshold = _minThreshold;
  maxThreshold = _maxThreshold;
}

function setStakingTime(uint256 _stakingTime) onlyOwner{
  stakingTime = _stakingTime;
}

function getAddress()returns(address){
  return address(this);
}

}
