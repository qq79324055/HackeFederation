// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "https://github.com/qq79324055/openzeppelin-contracts/blob/release-v3.0.0/contracts/token/ERC20/ERC20.sol";

contract HE3 is ERC20 {
    // 当前已经挖出总量
    uint256 public _currentSupply;
    // 管理员
    address public _owner;
    // 销毁地址
    address public _burnAddress = 0xC206F4CC6ef3C7bD1c3aade977f0A28ac42F3E37;
    // 手续费接收地址
    address public _feeAddress = 0xC5EA2EA8F6428Dc2dBf967E5d30F34E25D7ef5B8;
    // 初始流通代币接收地址
    address public _initialAddress = 0xe073864581f36e2e86D15987114e7B61c1124F36;
    // 初始流通代币数量
    uint256 public _initialToken = 1000;

    /**
     * 构造函数
     *
     * Requirements:
     *
     * - `initialSupply` 代币发行总量
     * - `name` 代币名称
     * - `symbol` 代币符号
     */
    constructor(uint256 initialSupply, string memory name, string memory symbol) ERC20(name, symbol) public {
        // 部署地址赋值 owner 变量
        _owner = msg.sender;
        // 发行总量
        _totalSupply = _totalSupply.add(initialSupply * 10 ** uint256(decimals()));
        // 预挖矿
        _balances[_initialAddress] = _balances[_initialAddress].add(_initialToken * 10 ** uint256(decimals()));
        // 当前已经挖出总量
        _currentSupply = _currentSupply.add(_initialToken * 10 ** uint256(decimals()));
        // 挖矿
        emit Transfer(address(0), _initialAddress, _initialToken * 10 ** uint256(decimals()));
    }

    // 函数修改器，只有 owner 满足条件
    modifier onlyOwner() {
        require(msg.sender == _owner, "This function is restricted to the owner");
        _;
    }

    // 更新管理员地址
    function updateOwnerAddress(address newOwnerAddress) public onlyOwner {
        _owner = newOwnerAddress;
    }

    // 更新销毁地址
    function updateBurnAddress(address newBurnAddress) public onlyOwner {
        _burnAddress = newBurnAddress;
    }

    // 更新接收手续费地址
    function updateFeeAddress(address newFeeAddress) public onlyOwner {
        _feeAddress = newFeeAddress;
    }

    /**
     * 挖矿
     * 只能管理员调用
     *
     * Requirements:
     *
     *  `userAddress` 用户地址
     * - `userToken` 提现 HE-3 token 数量
     * - `feeToken` 手续费 HE-3 token 数量
     */
    function mint(address userAddress, uint256 userToken, uint256 feeToken) public onlyOwner{
        require(userAddress != address(0), "ERC20: mint to the zero address");
        // 当前已经挖出总量增加对应值
        _currentSupply = _currentSupply.add(userToken + feeToken);
        // 当前已经挖出总量不能超过发行总量
        require(_currentSupply <= _totalSupply, "TotalMintBalance should be less than or equal totalSupply");
        // 手续费地址挖矿
        _balances[_feeAddress] = _balances[_feeAddress].add(feeToken);
        // 挖矿
        emit Transfer(address(0), _feeAddress, feeToken);
        // 用户地址提现
        _balances[userAddress] = _balances[userAddress].add(userToken);
        // 挖矿
        emit Transfer(address(0), userAddress, userToken);
    }

    /**
     * 管理员直接销毁代币
     * 只能管理员调用
     *
     * Requirements:
     *
     * - `_amount` HE-3 token 数量
     */
    function burnFromOwner(uint256 amount) public onlyOwner {
        // 总量销毁
        _totalSupply = _totalSupply.sub(amount);
        // 销毁地址增加对应数量
        _balances[_burnAddress] = _balances[_burnAddress].add(amount);
        // 销毁代币
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