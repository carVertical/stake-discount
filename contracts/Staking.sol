pragma solidity ^0.4.24;

import "./ERC20.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

contract Staking is Ownable{

IERC20 public cVToken;
uint256 public stakingTime; //In seconds
uint256 public minThreshold; //In wei
uint256 public maxThreshold; //In wei
uint256[] public discounts; //Stored in promiles (E.g 1% = 10, 10% = 100, 100% = 1000)
                            //Hence minimal possible discount is 0.1%

  using SafeMath for uint256;

constructor(
  IERC20 _cVToken,
  uint256 _stakingTime,
  uint256 _minThreshold,
  uint256 _maxThreshold,
  uint256[] _discounts)public{
    require(_cVToken != address(0));
    require(_minThreshold < _maxThreshold);
    cVToken = _cVToken;
    stakingTime = _stakingTime;
    setDiscounts(_minThreshold, _maxThreshold, _discounts);
  }

event DiscountsChanged();

event Staked(
  address who,
  uint256 amount);

event Unstaked(
  address who,
  uint256 amount);

event StakingTimeChanged(
  uint256 _newTimeToStake
  );

struct StakeInfo{

  uint256 unstakeTime;
  uint256 stakeAmount; //in Wei

}

mapping(address => StakeInfo) StakeTable;

function stakeOf(address staker)public view returns(uint256){
  return StakeTable[staker].stakeAmount;
}

function discountOf(address staker)public view returns(uint256){

  uint256 stakedAmount = stakeOf(staker);

  if(stakedAmount >= maxThreshold) return discounts[discounts.length-1];
  if(stakedAmount < minThreshold) return 0;

  uint256 N = discounts.length - 1;
  uint256 numerator = (stakedAmount.sub(minThreshold)).mul(N);
  uint256 denominator = maxThreshold.sub(minThreshold);

  uint256 discountIndex = uint256(numerator.div(denominator));

  return discounts[discountIndex];
}

function stake(uint256 amount) public { //Amount in wei

  address staker = msg.sender;

  require(cVToken.transferFrom(staker, address(this), amount)); //Transfer in wei

  if(StakeTable[staker].stakeAmount == 0){
  StakeTable[staker].unstakeTime = stakingTime.add(now);
  StakeTable[staker].stakeAmount = amount; // in wei
  }
  else{
    StakeTable[staker].stakeAmount = StakeTable[staker].stakeAmount.add(amount);
  }

  emit Staked(staker, amount);
}

function unstake() public{
address staker = msg.sender;

require(StakeTable[staker].unstakeTime <= now);
require(stakeOf(staker) > 0);

cVToken.transfer(staker, stakeOf(staker));

emit Unstaked(staker, stakeOf(staker));

StakeTable[staker].stakeAmount = 0;
StakeTable[staker].unstakeTime = 0;
}

function setDiscounts(uint256 _minThreshold, uint256 _maxThreshold, uint256[] _discounts) public onlyOwner{
  require(_minThreshold > 0);
  require(_minThreshold < _maxThreshold);

  require(_discounts.length > 0);
  require(_discounts[0] > 0);
  require(_discounts[_discounts.length - 1] < 1000);

  for(uint256 e = 0; e<_discounts.length - 1; e++){
      require(_discounts[e] < _discounts[e+1]);
  }

  minThreshold = _minThreshold;
  maxThreshold = _maxThreshold;
  discounts = _discounts;

  emit DiscountsChanged();
}

function setStakingTime(uint256 _stakingTime)public onlyOwner{
  require(_stakingTime > 0);
  stakingTime = _stakingTime;
  emit StakingTimeChanged(_stakingTime);
}

function getAddress()public view returns(address){
  return address(this);
}

function timeLeft(address _sender)public view returns(uint256){
  uint256 unstakingTime = StakeTable[_sender].unstakeTime;
  uint256 currentTime = now;

  if(unstakingTime < now) return 0;

  return unstakingTime.sub(currentTime);
}

}
