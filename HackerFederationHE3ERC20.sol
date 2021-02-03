// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/qq79324055/openzeppelin-contracts/blob/release-v3.0.0/contracts/token/ERC20/ERC20.sol";

contract HE3 is ERC20 {
    // Current supply
    uint256 public _currentSupply;
    // Manager
    address public _owner;
    // Burn address
    address public _burnAddress;
    // Fee address
    address public _feeAddress;
    // Initial Address
    address public _initialAddress;
    // Initial amount
    uint256 public _initialToken;

    /**
     * Constuctor func.
     *
     * Requirements:
     *
     * - `initialSupply`: total amount
     * - `name`: token name
     * - `symbol`: token symbol
     */
    constructor(
        uint256 initialSupply, 
        string memory name, 
        string memory symbol, 
        address initialAddress, 
        uint256 initialToken, 
        address feeAddress, 
        address burnAddress
    ) ERC20(name, symbol) public {
        _owner = msg.sender;
        _initialAddress = initialAddress;
        _initialToken = initialToken;
        _feeAddress = feeAddress;
        _burnAddress = burnAddress;
        _totalSupply = _totalSupply.add(initialSupply * 10 ** uint256(decimals()));
        _balances[_initialAddress] = _balances[_initialAddress].add(_initialToken * 10 ** uint256(decimals()));
        _currentSupply = _currentSupply.add(_initialToken * 10 ** uint256(decimals()));
        emit Transfer(address(0), _initialAddress, _initialToken * 10 ** uint256(decimals()));
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "This function is restricted to the owner");
        _;
    }

    modifier notAddress0(address newAddress) {
        require(newAddress != address(0), "Address should not be address(0)");
        _;
    }


    // Update owner
    function updateOwnerAddress(address newOwnerAddress) public onlyOwner notAddress0(newOwnerAddress) {
        _owner = newOwnerAddress;
    }

    // Update burn address
    function updateBurnAddress(address newBurnAddress) public onlyOwner notAddress0(newBurnAddress) {
        _burnAddress = newBurnAddress;
    }

    // Update fee address
    function updateFeeAddress(address newFeeAddress) public onlyOwner notAddress0(newFeeAddress) {
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
        uint256 mintTotal = userToken.add(feeToken);
        _currentSupply = _currentSupply.add(mintTotal);
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
