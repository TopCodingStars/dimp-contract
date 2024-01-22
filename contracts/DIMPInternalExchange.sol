// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DIMPInternalExchange is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => uint256) private _balances;
    mapping(address => bool) private _blacklist;

    uint256 private _minimumExchangeAmount;
    IERC20 private immutable _DIMP;

    event Deposit(address indexed depositer, uint256 depositAmount);
    event Withdraw(address indexed withdrawer, uint256 withdrawAmount);

    constructor(IERC20 DIMP_) Ownable(_msgSender()) {
        _DIMP = DIMP_;
        _minimumExchangeAmount = 1000000;
    }

    function minimumExchangeAmount() external view returns (uint256) {
        return _minimumExchangeAmount;
    }

    function DIMP() external view returns (IERC20) {
        return _DIMP;
    }

    function blacklisted(address user) external view returns (bool) {
        return _blacklist[user];
    }

    function setInternalBalance(address user, uint256 amount) external onlyOwner {
        _balances[user] = amount;
    }

    function setMinimumExchangeAmount(uint256 newMinimumExchangeAmount) external onlyOwner {
        require(newMinimumExchangeAmount > 0, "DIMPExchange: zero amount");
        _minimumExchangeAmount = newMinimumExchangeAmount;
    }

    function internalExchange(uint256 value) external nonReentrant {
        require(_blacklist[_msgSender()] == false, "DIMPExchange: blocked address");
        require(value >= _minimumExchangeAmount, "DIMPExchange: lower than minimum amount");

        unchecked {
            _balances[_msgSender()] += value;
        }
        _DIMP.safeTransferFrom(_msgSender(), address(this), value);

        emit Deposit(_msgSender(), value);
    }

    function withdraw(uint256 value) external nonReentrant {
        require(_blacklist[_msgSender()] == false, "DIMPExchange: blocked address");
        require(_balances[_msgSender()] >= value, "DIMPExchange: exceeds your deposits");
        require(value > 0, "DIMPExchange: zero amount");

        unchecked {
            _balances[_msgSender()] -= value;
        }
        _DIMP.safeTransfer(_msgSender(), value);

        emit Withdraw(_msgSender(), value);
    }

    function addBlacklist(address newBlocked) external onlyOwner {
        require(_blacklist[newBlocked] == false, "DIMPExchange: already blocked");
        _blacklist[newBlocked] = true;
    }

    function removeBlacklist(address newUnblocked) external onlyOwner {
        require(_blacklist[newUnblocked] == true, "DIMPExchange: already unblocked");
        _blacklist[newUnblocked] = false;
    }

    function internalBalance(address account) external view returns (uint256) {
        return _balances[account];
    }
}
