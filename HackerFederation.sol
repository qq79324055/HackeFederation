// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import 'https://github.com/qq79324055/openzeppelin-contracts/blob/release-v3.0.0/contracts/math/SafeMath.sol';

interface Token {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract HackerFederation {
    using SafeMath for uint256;

    // HE-1 decimals
    uint256 public usdtDecimals = 0;
    // Hashrate decimals
    uint256 public constant hashRateDecimals = 5;
    // 10 usdt = 1 T
    uint256 public constant hashRatePerUsdt = 10;
    // Manager address
    address public owner;
    // Root address
    address public rootAddress = 0x3585762FBFf4b2b7D92Af16b2BCfa90FE3562087;
    // Burn address
    address public burnAddress = 0xC206F4CC6ef3C7bD1c3aade977f0A28ac42F3E37;

    // DAI-HE3 pair address
    address public daiToHe3Address = address(0x002b48f9e6ca23e71b6cf52199db9a7c1a97cd0cd7);

    // DAI ERC20 address
    address public daiTokenAddress = 0x97509bF13910E046f7000ECa4fE06354E11f670A;
    Token tokenDai = Token(daiTokenAddress);
    // HE-3 ERC20 address
    address public he3TokenAddress = 0x7559A5416CED9059411Db88DAA5fEb34f140d7D5;
    Token tokenHe3 = Token(he3TokenAddress);

    // HE-1 ERC20 address
    address public he1TokenAddress = 0xF72e4d8B029c4fC6a97c59EC3AF33b2cCcC52715;

    // Userinfo
    struct User {
        address superior;
        uint256 hashRate;
        bool isUser;
    }
    mapping(address => User) public users;

    // Buy hashrate event
    event LogBuyHashRate(address indexed owner, address indexed superior, uint256 hashRate);

    constructor() public {
        // Init owner
        owner = msg.sender;
    }

    // Modifier func
    modifier onlyOwner() {
        require(msg.sender == owner, "This function is restricted to the owner");
        _;
    }

    /**
     * Use HE-1 to buy hashrate
     *
     * Requirements:
     *
     * - `_tokenAmount`: Amount of HE-1 
     * - `_superior`: User's inviter
     */
    function buyHashRateWithHE1(uint256 _tokenAmount, address _superior) public {
        // 
        uint256 total = _tokenAmount.div(10 ** usdtDecimals);
        //
        _buyHashRate(he1TokenAddress, _tokenAmount, total, _superior);
    }

    /**
     * Use HE-3 to buy hashrate
     *
     * Requirements:
     *
     * - `_tokenAmount`: Amount of HE-3
     * - `_superior`: User's inviter
     */
    function buyHashRateWithHE3(uint256 _tokenAmount, address _superior) public {
        // 
        uint256 totalDai = getHe3ToDai(_tokenAmount);
        //
        _buyHashRate(he3TokenAddress, _tokenAmount, totalDai.div(10**12), _superior);
    }

    /**
     * Buy hashrate
     *
     * Requirements:
     *
     * - `_token`: HE-1 or HE-3 address
     * - `_tokenAmount`: Amount of token
     * - `_usdtAmount`: Value of _tokenAmount to USDT
     * - `_superior`: inviter
     */
    function _buyHashRate(address _tokenAddress,uint256 _tokenAmount, uint256 _usdtAmount, address _superior) internal {
        // require _superior
        if (!(users[_superior].isUser || _superior == rootAddress)) {
            require(false, "Superior should be a user or rootAddress");
        }
        
        // burn the token sent by user
        bool sent = Token(_tokenAddress).transferFrom(msg.sender, burnAddress, _tokenAmount);
        require(sent, "Token transfer failed");

        // USDT decimals = 6
        require(_usdtAmount >= 10000000, "Usdt should be great than or equal 10");
        
        uint256 hashRate = _usdtAmount.div(10).div(hashRatePerUsdt);
        if (users[msg.sender].isUser) {
            users[msg.sender].hashRate = users[msg.sender].hashRate.add(hashRate);
        } else {
            users[msg.sender].superior = _superior;
            users[msg.sender].hashRate = hashRate;
            users[msg.sender].isUser = true;
        }
        
        // Buy hashrate event
        emit LogBuyHashRate(msg.sender, _superior, hashRate);
    }

    // Update owner address
    function updateOwnerAddress(address _newOwnerAddress) public onlyOwner {
        owner = _newOwnerAddress;
    }

    // Update burn address
    function updateBurnAddress(address _newBurnAddress) public onlyOwner {
        burnAddress = _newBurnAddress;
    }

    // update HE-3 contract address
    function updateHe3TokenAddress(address _he3TokenAddress) public onlyOwner {
        he3TokenAddress = _he3TokenAddress;
        tokenHe3 = Token(he3TokenAddress);
    }

    // update HE-1 contract address
    function updateHe1TokenAddress(address _he1TokenAddress) public onlyOwner {
        he1TokenAddress = _he1TokenAddress;
    }

    // update DAI contract address
    function updateDaiToHe3AddressAddress(address _daiToHe3Address) public onlyOwner {
        daiToHe3Address = _daiToHe3Address;
    }

    // update DAI-HE3 uniswap pair contract address
    function updateDaiTokenAddress(address _daiTokenAddress) public onlyOwner {
        daiTokenAddress = _daiTokenAddress;
        tokenDai = Token(daiTokenAddress);
    }

    //
    function updateUsdtDecimals(uint256 _newUsdtDecimals) public onlyOwner {
        usdtDecimals = _newUsdtDecimals;
    }

    /**
     * Is user?
     */
    function isUser(address _userAddress) public view returns (bool) {
        return users[_userAddress].isUser;
    }

    // Get amount 1 HE3 to DAI
    function getDaiPerHe3() public view returns (uint256) {
        return getHe3ToDai(10**18);
    }

    // Get amount _he3Amount HE3 to DAI 
    function getHe3ToDai(uint256 _he3Amount) internal view returns (uint256) {
        return tokenDai.balanceOf(daiToHe3Address).mul(_he3Amount).div(tokenHe3.balanceOf(daiToHe3Address));
    }
}
