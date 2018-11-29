const StakeContract = artifacts.require('./Staking.sol')
const cVToken = artifacts.require('./cVTokenOnly/cVToken.sol')

const chai = require('chai');
var BigNumber = require('bignumber.js');

const should = chai.should;

const OneToken = new BigNumber(web3.toWei(1, 'ether'));

const amount_to_mint1 = BigNumber(OneToken.times(465570989));
const amount_to_mint2 = BigNumber(OneToken.times(465573989));
const minThreshold = 100;
const maxThreshold = 3000;

const discounts = [2,4,6,8,10,12,14,16,18,20];

contract('StakeContract', async (accounts) => {

  it('Owner should be set', async () => {

    const StakeInstance = await StakeContract.deployed();
    const actualOwner = await StakeInstance.owner.call();

    assert.equal(accounts[0],actualOwner,"Owner is not set or it is set wrong");
  });

  it('Staking should work', async() => {

    const StakeInstance = await StakeContract.deployed();
    const cVinstance = await cVToken.deployed();
    const stakeAddress = await StakeInstance.getAddress.call()

    await cVinstance.changeTransferLock(0, {from: accounts[0]});

    await cVinstance.mint(accounts[1],amount_to_mint1.valueOf(), {from: accounts[0]});
    await cVinstance.approve(stakeAddress,amount_to_mint1.valueOf(), {from: accounts[1]});

    await StakeInstance.stake(amount_to_mint1.valueOf(), {from: accounts[1]});

    const balanceOfStake = await cVinstance.balanceOf.call(stakeAddress);
    const stakedAmount = await StakeInstance.stakeOf.call(accounts[1]);
    assert.equal(stakedAmount.valueOf(),balanceOfStake.valueOf(),"Staked amount does not equal contract balance");

    expect(balanceOfStake.valueOf()).to.equal(amount_to_mint1.valueOf());
  });

  it('Unstaking should work', async() => {

    const StakeInstance = await StakeContract.deployed();
    const cVinstance = await cVToken.deployed();

    const stakeAddress = await StakeInstance.getAddress.call();

    await cVinstance.changeTransferLock(0, {from: accounts[0]});

    await cVinstance.mint(accounts[1],amount_to_mint1.valueOf(), {from: accounts[0]});
    await cVinstance.approve(stakeAddress,amount_to_mint1.valueOf(), {from: accounts[1]});

    await StakeInstance.stake(amount_to_mint1.valueOf(), {from: accounts[1]});

  try{
    await StakeInstance.unstake({from: accounts[0]})}
    catch(err){assert(err,"Should not be able to unstake ahead of time ")}

    await web3.currentProvider.send({
       jsonrpc: "2.0",
       method: "evm_increaseTime",
       params: [200], //Advance time by 200 seconds
       id: 123
       });

    const amountStaked = await StakeInstance.stakeOf.call(accounts[1]);

    await StakeInstance.unstake({from: accounts[1]});

    balanceAfterUnstake = await cVinstance.balanceOf.call(accounts[1]);

    assert.equal(amountStaked.valueOf(),balanceAfterUnstake.valueOf(),"Staker does not receive all tokens");
  });

  it("Threshold and discount setup should work", async() =>{

    const StakeInstance = await StakeContract.deployed();

    await StakeInstance.setDiscounts(minThreshold, maxThreshold, discounts, {from: accounts[0]});

    for(e=0; e<10; e++){
      actualDiscountValue = await StakeInstance.discounts.call(e);
      assert.equal(actualDiscountValue.valueOf(),discounts[e].valueOf(),"Discount is not set or setup is incorrect")
    }

    minThresholdValue = await StakeInstance.minThreshold.call();
    maxThresholdValue = await StakeInstance.maxThreshold.call();
    assert.equal(minThresholdValue.valueOf(),minThreshold,"Min threshold is not set or setup is incorrect");
    assert.equal(maxThresholdValue.valueOf(),maxThreshold,"Max threshold is not set or setup is incorrect");
  });

  it("Discount levels should work correctly", async() =>{

    const StakeInstance = await StakeContract.deployed();

    const testStake = 2000;

    await StakeInstance.setDiscounts(minThreshold, maxThreshold, discounts, {from: accounts[0]});

    const cVinstance = await cVToken.deployed();

    const stakeAddress = await StakeInstance.getAddress.call();

    await cVinstance.changeTransferLock(0, {from: accounts[0]});

    await cVinstance.mint(accounts[1],testStake, {from: accounts[0]});
    await cVinstance.approve(stakeAddress, testStake, {from: accounts[1]});

    await StakeInstance.stake(testStake, {from: accounts[1]});

    const discountOf = await StakeInstance.discountOf.call(accounts[1]);

    assert.equal(discountOf.valueOf(), 12, "Discount is not correct");
  });

});
