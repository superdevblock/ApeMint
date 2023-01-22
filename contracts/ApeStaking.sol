
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";


interface IERC20 {

    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ApeStaking is Ownable {
    using SafeMath for uint256;

    address public rtoken;
    address public apeAddress;
    
    
    uint256 public RewardTokenPerBlock;

    struct UserInfo {
        uint256 tokenId;
        uint256 startBlock;
    }

    mapping(address => UserInfo[]) public userInfo;
    mapping(address => uint256) public stakingAmount;

    event Stake(address indexed user, uint256 amount);
    event UnStake(address indexed user, uint256 amount);

    function changeRewardTokenAddress(address _rewardTokenAddress) public onlyOwner {
        rtoken = _rewardTokenAddress;
    }

    function changeAPETokenAddress(address _apeTokenAddress) public onlyOwner {
        apeAddress = _apeTokenAddress;
    }

    function changeRewardTokenPerBlock(uint256 _RewardTokenPerBlock) public onlyOwner {
        RewardTokenPerBlock = _RewardTokenPerBlock;
    }

    constructor(address _variable, address _ape) {
        RewardTokenPerBlock = 40 ether;
        changeRewardTokenAddress(_variable);
        changeAPETokenAddress(_ape);
    }
    function approve(address tokenAddress, address spender, uint256 amount) public onlyOwner returns (bool) {
      IERC20(tokenAddress).approve(spender, amount);
      return true;
    }
    function pendingReward(address _user, uint256 _tokenId) public view returns (uint256) {

        (bool _isStaked, uint256 _startBlock) = getStakingItemInfo(_user, _tokenId);
        if(!_isStaked) return 0;
        uint256 currentBlock = block.number;

        uint256 rewardAmount = (currentBlock.sub(_startBlock)).mul(RewardTokenPerBlock);
        if(userInfo[_user].length >= 5) rewardAmount = rewardAmount.mul(3).div(2);
        return rewardAmount;
    }

    function pendingTotalReward(address _user) public view returns(uint256) {
        uint256 pending = 0;
        for (uint256 i = 0; i < userInfo[_user].length; i++) {
            uint256 temp = pendingReward(_user, userInfo[_user][i].tokenId);
            pending = pending.add(temp);
        }
        return pending;
    }

    function stake(uint256[] memory tokenIds) public {
        for(uint256 i = 0; i < tokenIds.length; i++) {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(_isStaked) continue;
            if(IERC721(apeAddress).ownerOf(tokenIds[i]) != msg.sender) continue;

            IERC721(apeAddress).transferFrom(address(msg.sender), address(this), tokenIds[i]);

            UserInfo memory info;
            info.tokenId = tokenIds[i];
            info.startBlock = block.number;

            userInfo[msg.sender].push(info);
            stakingAmount[msg.sender] = stakingAmount[msg.sender] + 1;
            emit Stake(msg.sender, 1);
        }
    }

    function unstake(uint256[] memory tokenIds) public {
        uint256 pending = 0;
        for(uint256 i = 0; i < tokenIds.length; i++) {
            (bool _isStaked,) = getStakingItemInfo(msg.sender, tokenIds[i]);
            if(!_isStaked) continue;
            if(IERC721(apeAddress).ownerOf(tokenIds[i]) != address(this)) continue;

            uint256 temp = pendingReward(msg.sender, tokenIds[i]);
            pending = pending.add(temp);
            
            removeFromUserInfo(tokenIds[i]);
            if(stakingAmount[msg.sender] > 0)
                stakingAmount[msg.sender] = stakingAmount[msg.sender] - 1;
            IERC721(apeAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
            emit UnStake(msg.sender, 1);
        }

        if(pending > 0) {
            IERC20(rtoken).transfer(msg.sender, pending);
        }
    }

    function getStakingItemInfo(address _user, uint256 _tokenId) public view returns(bool _isStaked, uint256 _startBlock) {
        for(uint256 i = 0; i < userInfo[_user].length; i++) {
            if(userInfo[_user][i].tokenId == _tokenId) {
                _isStaked = true;
                _startBlock = userInfo[_user][i].startBlock;
                break;
            }
        }
    }

    function removeFromUserInfo(uint256 tokenId) private {        
        for (uint256 i = 0; i < userInfo[msg.sender].length; i++) {
            if (userInfo[msg.sender][i].tokenId == tokenId) {
                userInfo[msg.sender][i] = userInfo[msg.sender][userInfo[msg.sender].length - 1];
                userInfo[msg.sender].pop();
                break;
            }
        }        
    }

    function claim() public {

        uint256 reward = pendingTotalReward(msg.sender);

        for (uint256 i = 0; i < userInfo[msg.sender].length; i++)
            userInfo[msg.sender][i].startBlock = block.number;

        IERC20(rtoken).transfer(msg.sender, reward);
    }
}