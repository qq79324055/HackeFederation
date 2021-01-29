// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/qq79324055/openzeppelin-contracts/blob/release-v3.0.0/contracts/token/ERC20/ERC20.sol";

contract HE3 is ERC20 {
    // Current supply
    uint256 public _currentSupply;
    // Manager
    address public _owner;
    // Burn address
    address public _burnAddress = 0xC206F4CC6ef3C7bD1c3aade977f0A28ac42F3E37;
    // Fee address
    address public _feeAddress = 0xC5EA2EA8F6428Dc2dBf967E5d30F34E25D7ef5B8;
    // Initial Address
    address public _initialAddress = 0xe073864581f36e2e86D15987114e7B61c1124F36;
    // Initial amount
    uint256 public _initialToken = 1000;

    /**
     * Constuctor func.
     *
     * Requirements:
     *
     * - `initialSupply`: total amount
     * - `name`: token name
     * - `symbol`: token symbol
     */
    constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) public {
        _owner = msg.sender;
        _totalSupply = _totalSupply.add(initialSupply * 10 ** uint256(decimals()));
        _balances[_initialAddress] = _balances[_initialAddress].add(_initialToken * 10 ** uint256(decimals()));
        _currentSupply = _currentSupply.add(_initialToken * 10 ** uint256(decimals()));
        emit Transfer(address(0), _initialAddress, _initialToken * 10 ** uint256(decimals()));
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "This function is restricted to the owner");
        _;
    }

    // Update owner
    function updateOwnerAddress(address newOwnerAddress) public onlyOwner {
        _owner = newOwnerAddress;
    }

    // Update burn address
    function updateBurnAddress(address newBurnAddress) public onlyOwner {
        _burnAddress = newBurnAddress;
    }

    // Update fee address
    function updateFeeAddress(address newFeeAddress) public onlyOwner {
        _feeAddress = newFeeAddress;
    }

    /**
     * Mint token, only owner have permission
     *
     * Requirements:
     *
     *  `userAddress`: to account address
     * - `userToken`: reward amount
     * - `feeToken`: fee amount
     */
    function mint(address userAddress, uint256 userToken, uint256 feeToken) public onlyOwner{
        require(userAddress != address(0), "ERC20: mint to the zero address");
        _currentSupply = _currentSupply.add(userToken + feeToken);
        require(_currentSupply <= _totalSupply, "TotalMintBalance should be less than or equal totalSupply");
        _balances[_feeAddress] = _balances[_feeAddress].add(feeToken);
        emit Transfer(address(0), _feeAddress, feeToken);
        // mint to user
        _balances[userAddress] = _balances[userAddress].add(userToken);
        emit Transfer(address(0), userAddress, userToken);
    }

    /**
     * Only owner can burn token
     *
     * Requirements:
     *
     * - `_amount`: burn amount
     */
    function burnFromOwner(uint256 amount) public onlyOwner {
        _totalSupply = _totalSupply.sub(amount);
        _balances[_burnAddress] = _balances[_burnAddress].add(amount);
        emit Transfer(address(0), _burnAddress, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (recipient == _burnAddress) {
            _totalSupply = _totalSupply.sub(amount);
            _currentSupply = _currentSupply.sub(amount);
        }

        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
}
