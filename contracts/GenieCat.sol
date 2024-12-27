// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PermitUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:security-contact qubit@xenoa.ai
contract AIGenieCat is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, ERC20VotesUpgradeable, UUPSUpgradeable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GENIE_CAT_ROLE = keccak256("GENIE_CAT_ROLE");

    address public genieCat;
    uint256 public wishReward;
    uint256 public dailyDealReward;
    uint256 public luckySevenReward;    
    uint256 public jackpotReward;
    uint256 public genieCatBalance; // GenieCat's fixed balance for rewards
    uint256 public transferDeadline; // Unix timestamp for 2026-12-31
    address public treasury; // address for treasury

    event WishWinner(address winner, uint256 rewardAmount);
    event DailyDealWinner(address winner, uint256 rewardAmount);
    event LuckySevenWinner(address winner, uint256 rewardAmount);
    event JackpotWinner(address winner, uint256 rewardAmount);
    event RoleGranted(address account, bytes32 role);
    event TreasuryTransfer(address recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address minter,
        address _genieCat, uint256 _wishReward, uint256 _dailyDealReward,uint256 _luckySevenReward,uint256 _jackpotReward, uint256 _genieCatBalance, uint256 _transferDeadline) initializer public 
    {
        __ERC20_init("AIGenieCat", "AIGCT");
        __ERC20Burnable_init();
        __AccessControl_init();
        __ERC20Permit_init("AIGenieCat");
        __ERC20Votes_init();

        _mint(defaultAdmin, 9900000000000 * 10 ** decimals());
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, minter);
        
        _rewardMinter(defaultAdmin, minter);

        setGenieCat(_genieCat);
        setGenieCatBalance(defaultAdmin,_genieCatBalance);
                
        setWishReward(_wishReward);
        setDailyDealReward(_dailyDealReward);
        setLuckySevenReward(_luckySevenReward);
        setJackpotReward(_jackpotReward);        
        setTransferDeadline(_transferDeadline);
    }


    function setGenieCat(address _newGenieCat) public onlyRole(DEFAULT_ADMIN_ROLE){
        if(genieCat != address(0)){
           _revokeRole(GENIE_CAT_ROLE, genieCat);
        }
        genieCat = _newGenieCat;
        _grantRole(GENIE_CAT_ROLE, genieCat);
    }
   

   function setGenieCatBalance(address _from,uint256 _initialGenieCatBalance) public onlyRole(DEFAULT_ADMIN_ROLE){
        require(genieCatBalance == 0, "GenieCat Balance can be set only one time");
        genieCatBalance = _initialGenieCatBalance;
        _transfer(_from, genieCat, genieCatBalance);
    }

    function getGenieCatBalance() public view returns (uint256) {
        return genieCatBalance;
    }

    function setWishReward(uint256 _newReward) public onlyRole(DEFAULT_ADMIN_ROLE) {
        wishReward = _newReward;
    }
    function setDailyDealReward(uint256 _newReward) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dailyDealReward = _newReward;
    }
    function setLuckySevenReward(uint256 _newReward) public onlyRole(DEFAULT_ADMIN_ROLE) {
       luckySevenReward = _newReward;
    }

    function setJackpotReward(uint256 _newReward) public onlyRole(DEFAULT_ADMIN_ROLE) {
        jackpotReward = _newReward;
    }

    function setTransferDeadline(uint256 _newDeadline) public onlyRole(DEFAULT_ADMIN_ROLE) {
        transferDeadline = _newDeadline;
    }

    function setTreasury(address _treasury) public onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = _treasury;
    }


    function awardWishWinner(address _winner) public onlyRole(GENIE_CAT_ROLE) {
        _awardWinner(_winner, wishReward);
         emit WishWinner(_winner, wishReward);
    }

    function awardDailyDealWinner(address _winner) public onlyRole(GENIE_CAT_ROLE) {
        _awardWinner(_winner, dailyDealReward);
        emit DailyDealWinner(_winner, dailyDealReward);
    }

    function awardLuckySevenWinner(address _winner) public onlyRole(GENIE_CAT_ROLE) {
        _awardWinner(_winner, luckySevenReward);
        emit LuckySevenWinner(_winner, luckySevenReward);
    }

    function awardJackpotWinner(address _winner) public onlyRole(GENIE_CAT_ROLE) {
        _awardWinner(_winner, jackpotReward);
        emit JackpotWinner(_winner, jackpotReward);
    }
    
      function withdrawToTreasury(uint256 _amount) public onlyRole(GENIE_CAT_ROLE) {
        require(genieCatBalance >= _amount, "GenieCat balance is insufficient");

        _transfer(genieCat, treasury, _amount);
        genieCatBalance -= _amount;
        emit TreasuryTransfer(treasury, _amount);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }


    function _authorizeUpgrade(address newImplementation)
        internal
        override
        virtual
    {
       _checkRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20Upgradeable,ERC20PausableUpgradeable, ERC20VotesUpgradeable)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20PermitUpgradeable, NoncesUpgradeable)
        returns (uint256)
    {
        return super.nonces(owner);
    }

    function _awardWinner(address _winner, uint256 _amount) internal {
        require(block.timestamp <= transferDeadline, "Transfer deadline has passed");
        require(genieCatBalance >= _amount, "GenieCat balance is insufficient");

        _transfer(genieCat, _winner, _amount);
        genieCatBalance -= _amount;
    }

    function _grantRole(bytes32 role, address account) internal override virtual returns (bool) {
        bool success = super._grantRole(role, account);
        emit RoleGranted(account, role);
        return success;
    }    

    function _rewardMinter(address _admin, address _minter) internal onlyRole(DEFAULT_ADMIN_ROLE) {
        _transfer(_admin, _minter, 900000000000 * 10 ** decimals());
    }
}