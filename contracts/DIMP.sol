// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract DIMP is Ownable {
    using Math for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isWhitelisted;

    address[] private _swapAddresses;

    address private _liquidity;
    address private _ecosystem;
    address private _partnership;

    uint256 private _totalSupply = 237279209162 * 10 ** 6;

    string private constant _name = "Direct Impact Monetary Piece";
    string private constant _symbol = "DIMP";

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        address[] memory whitelistedAddresses,
        uint256[] memory whitelistedAmounts,
        address liquidity_,
        address ecosystem_,
        address partnership_
    ) Ownable(_msgSender()) {
        uint256 totalAmounts = 0;

        require(
            liquidity_ != address(0) && ecosystem_ != address(0) && partnership_ != address(0),
            "DIMP: zero address"
        );

        _liquidity = liquidity_;
        _ecosystem = ecosystem_;
        _partnership = partnership_;

        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            require(whitelistedAddresses[i] != address(0), "DIMP: zero address");

            totalAmounts += whitelistedAmounts[i];

            _balances[whitelistedAddresses[i]] = whitelistedAmounts[i];

            emit Transfer(address(0), whitelistedAddresses[i], whitelistedAmounts[i]);
        }

        require(totalAmounts == _totalSupply, "DIMP: mismatched total amounts");
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 6;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function setLiquidity(address newLiquidity) external onlyOwner {
        require(_liquidity != newLiquidity, "DIMP: same address");
        require(newLiquidity != address(0), "DIMP: zero address");
        _liquidity = newLiquidity;
    }

    function setEcosystem(address newEcosystem) external onlyOwner {
        require(_ecosystem != newEcosystem, "DIMP: same address");
        require(newEcosystem != address(0), "DIMP: zero address");
        _ecosystem = newEcosystem;
    }

    function setPartnership(address newPartnership) external onlyOwner {
        require(_partnership != newPartnership, "DIMP: same address");
        require(newPartnership != address(0), "DIMP: zero address");
        _partnership = newPartnership;
    }

    function addPairAddress(address newSwapAddress) external onlyOwner {
        require(newSwapAddress != address(0), "DIMP: zero address");
        _swapAddresses.push(newSwapAddress);
    }

    function addWhitelist(address newWhitelisted) external onlyOwner {
        require(newWhitelisted != address(0), "DIMP: zero address");
        _isWhitelisted[newWhitelisted] = true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(_msgSender(), spender, amount, true);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "DIMP: invalid sender");
        require(to != address(0), "DIMP: invalid receiver");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "DIMP: transfer amount exceeds balance");

        uint256 feeAmount = 0;

        if (!_isWhitelisted[from]) {
            for (uint256 i; i < _swapAddresses.length; i++) {
                if (to == _swapAddresses[i]) {
                    feeAmount = amount.mulDiv(3, 100, Math.Rounding.Ceil);

                    // move fee to `DIMP` contract
                    unchecked {
                        _balances[address(this)] += feeAmount;
                    }
                    uint256 dimpBalance = _balances[address(this)];

                    if (dimpBalance >= 10000) {
                        uint256 sharesOfPartnership = dimpBalance / 3;
                        uint256 sharesOfEcosystem = dimpBalance / 3;
                        uint256 sharesOfLiquidity = dimpBalance -
                            sharesOfPartnership -
                            sharesOfEcosystem;

                        unchecked {
                            _balances[_partnership] += sharesOfPartnership;
                            _balances[_ecosystem] += sharesOfEcosystem;
                            _balances[_liquidity] += sharesOfLiquidity;
                            _balances[address(this)] = 0;
                        }
                    }
                    break;
                }
            }
        }

        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount - feeAmount;
        }

        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount, bool emitEvent) internal {
        require(owner != address(0), "DIMP: approve from the zero address");
        require(spender != address(0), "DIMP: approve to the zero address");
        _allowances[owner][spender] = amount;
        if (emitEvent) {
            emit Approval(owner, spender, amount);
        }
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "DIMP: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}
