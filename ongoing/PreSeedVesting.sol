// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract PreSeedVesting is Ownable, ReentrancyGuard {
    using Math for uint256;
    using SafeERC20 for IERC20;

    /* the TGE time of the DIMP */
    uint256 private tgeTime;

    /* the duration of the Pre-Seed vesting */
    uint256 private duration;

    /* the price (in USDT) of 1 DIMP */
    uint256 private price;

    /* the address of the token contract */
    IERC20 private tokenReward;

    /* the balances (in USDT) of all investors */
    mapping(address => uint256) public balanceOfUSDT;

    /* the balances (in DIMP) of all investors */
    mapping(address => uint256) public balanceOfDIMP;

    /* the whitelist of the Pre-Seed sale */
    mapping(address => bool) public whitelist;

    /* the amount of the token already released */
    mapping(address => uint256) public releasedAmount;

    event TokensReleased(address addr, uint256 amount);

    constructor(IERC20 _token, uint256 _tge) {
        tokenReward = _token;
        tgeTime = _tge;
        price = 250; // 0.00025 USD
        duration = 60 * 60 * 24 * 7 * 100; // 100 weeks
    }

    modifier onlyWhitelisted() {
        require(whitelist[_msgSender()] == true, "Caller is not whitelisted");
        _;
    }

    function updatetgeTime(uint256 _tge) external onlyOwner {
        tgeTime = _tge;
    }

    function updateDuration(uint256 _duration) external onlyOwner {
        duration = _duration;
    }

    function checkFunds(address addr) external view returns (uint256) {
        return balanceOfUSDT[addr];
    }

    function checkDIMPFunds(address addr) external view returns (uint256) {
        return balanceOfDIMP[addr];
    }

    function isWhitelisted(address addr) external view returns (bool) {
        return whitelist[addr];
    }

    function addWhitelisted(address addr, uint256 amount) external onlyOwner {
        whitelist[addr] = true;
        balanceOfUSDT[addr] = balanceOfUSDT[addr].add(amount);
        balanceOfDIMP[addr] = balanceOfDIMP[addr].add(amount.div(price) * 10 ** 6);
    }

    function removeWhitelisted(address addr) external onlyOwner {
        whitelist[addr] = false;
    }

    modifier afterClosed() {
        require(block.timestamp >= tgeTime, "Before-TGE");
        _;
    }

    /**
     * @dev
     * Transfers vested tokens to beneficiary.
     */
    function claim() external afterClosed onlyWhitelisted nonReentrant {
        require(balanceOfDIMP[msg.sender] > 0, "Non-contribution");

        uint256 unreleasedAmount = _releasableAmount(msg.sender);
        require(unreleasedAmount > 0, "All-claimed");

        uint256 balance = tokenReward.balanceOf(address(this));
        require(balance >= unreleasedAmount, "Lack-of-funds");

        releasedAmount[msg.sender] = releasedAmount[msg.sender].add(unreleasedAmount);

        tokenReward.safeTransfer(msg.sender, unreleasedAmount);

        emit TokensReleased(msg.sender, unreleasedAmount);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param addr beneficiary
     */
    function _releasableAmount(address addr) private view returns (uint256) {
        return _vestedAmount(addr).sub(releasedAmount[addr]);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param addr beneficiary
     */
    function _vestedAmount(address addr) private view returns (uint256) {
        // before 1 month cliff
        if (block.timestamp < tgeTime) {
            return 0;
            // after 1 month cliff + duration
        } else if (block.timestamp > tgeTime.add(duration)) {
            return balanceOfDIMP[addr];
            // linear part during 1 month cliff + 12 months
        } else {
            uint256 linearPart = balanceOfDIMP[addr];
            return linearPart.mul(block.timestamp.sub(tgeTime)).div(duration);
        }
    }
}
