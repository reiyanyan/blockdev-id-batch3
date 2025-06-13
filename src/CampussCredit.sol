// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CampusCredit is ERC20, ERC20Burnable, Pausable, AccessControl {
    // TODO: Define role constants
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Additional features untuk kampus
    mapping(address => uint256) public dailySpendingLimit;
    mapping(address => uint256) public spentToday;
    mapping(address => uint256) public lastSpendingReset;

    // Merchant whitelist
    // mapping(address => bool) public isMerchant;
    // mapping(address => string) public merchantName;
    /* -------------------------------------------------------------------------- */
    /*                        Revised -> Merchant whitelist                       */
    /*                          merged into one mappings                          */
    /* -------------------------------------------------------------------------- */
    mapping(address => string) public merchants;

    /* -------------------------------------------------------------------------- */
    /*                                Experiments:                                */
    /*       creating mine, while built-in already had `onlyRole()` modifier      */
    /* -------------------------------------------------------------------------- */
    modifier rolePolicy(bytes32 role) {
        AccessControl._checkRole(role);
        _;
    }

    modifier validMerchant(address merchant) {
        require(
            bytes(merchants[merchant]).length > 0,
            "Invalid merchant address"
        );
        _;
    }

    constructor() ERC20("Campus Credit", "CREDIT") {
        // TODO: Setup roles
        // 1. Grant DEFAULT_ADMIN_ROLE ke msg.sender
        // 2. Grant PAUSER_ROLE ke msg.sender
        // 3. Grant MINTER_ROLE ke msg.sender
        // 4. Consider initial mint untuk treasury

        /* ------------------ super will search from linear inherit ----------------- */
        super._grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        /* -------------------------------- explicit -------------------------------- */
        AccessControl.grantRole(PAUSER_ROLE, msg.sender);
        AccessControl.grantRole(MINTER_ROLE, msg.sender);

        ERC20._mint(msg.sender, 1_000 * 10 ** decimals());
    }

    /**
     * @dev Pause all token transfers
     * Use case: Emergency atau maintenance
     */
    function pause() public rolePolicy(PAUSER_ROLE) {
        // TODO: Implement dengan role check
        // Only PAUSER_ROLE can pause
        Pausable._pause();
    }

    function unpause() public rolePolicy(PAUSER_ROLE) {
        // TODO: Implement unpause
        Pausable._unpause();
    }

    /**
     * @dev Mint new tokens
     * Use case: Top-up saldo mahasiswa
     */
    function mint(address to, uint256 amount) public rolePolicy(MINTER_ROLE) {
        // TODO: Implement dengan role check
        // Only MINTER_ROLE can mint
        // Consider adding minting limits
        require(amount > 0, "Mint amount must be > 0");
        _mint(to, amount);
    }

    /**
     * @dev Register merchant
     * Use case: Kafetaria, toko buku, laundry
     */
    function registerMerchant(
        address merchant,
        string memory name
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO: Register merchant untuk accept payments
        merchants[merchant] = name;
    }

    /**
     * @dev Set daily spending limit untuk mahasiswa
     * Use case: Parental control atau self-control
     */
    function setDailyLimit(
        address student,
        uint256 limit
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO: Set spending limit
        dailySpendingLimit[student] = limit;
        spentToday[student] = 0;
        lastSpendingReset[student] = timeToDayID();
    }

    /**
     * @dev Transfer dengan spending limit check
     */
    function transferWithLimit(address _to, uint256 _amount) public {
        // TODO: Check daily limit before transfer
        // Reset limit if new day
        // Update spent amount
        // Then do normal transfer

        // if a new day
        uint256 today = timeToDayID();
        if (lastSpendingReset[msg.sender] != today) {
            lastSpendingReset[msg.sender] = today;
            spentToday[msg.sender] = 0;
        }

        uint willSpent = spentToday[msg.sender] + _amount;
        uint limit = dailySpendingLimit[msg.sender];
        require(willSpent <= limit, "Exceeds daily limiy");

        // update
        spentToday[msg.sender] += _amount;

        // transfer
        ERC20.transfer(_to, _amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   REMOVED                                  */
    /* -------------------------------------------------------------------------- */
    // function _beforeTokenTransfer() internal virtual override {}

    /**
     * ref: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/5146
     */

    /* -------------------------------------------------------------------------- */
    /*                               OpenZeppelin v5                              */
    /* -------------------------------------------------------------------------- */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        // TODO: Add pause check
        // super._beforeTokenTransfer(from, to, amount);
        // require(!paused(), "Token transfers paused");
        require(!paused(), "Token transfers paused"); // Check FIRST
        super._update(from, to, value); // Then execute
    }

    /**
     * @dev Cashback mechanism untuk encourage usage
     */
    uint256 public cashbackPercentage = 2; // 2%

    function transferWithCashback(
        address merchant,
        uint256 amount
    ) public validMerchant(merchant) {
        // TODO: Transfer to merchant dengan cashback ke sender
        // Calculate cashback
        // Transfer main amount
        // Mint cashback to sender
        require(amount > 0, "Amount must be > 0");

        // if a new day
        uint256 today = timeToDayID();
        if (lastSpendingReset[msg.sender] != today) {
            lastSpendingReset[msg.sender] = today;
            spentToday[msg.sender] = 0;
        }

        uint willSpent = spentToday[msg.sender] + amount;
        uint limit = dailySpendingLimit[msg.sender];
        require(willSpent <= limit, "Exceeds daily limiy");

        // update
        spentToday[msg.sender] += amount;

        ERC20.transfer(merchant, amount);

        uint256 cashback = (amount * cashbackPercentage) / 100;
        ERC20._mint(msg.sender, cashback);
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Helper                                   */
    /* -------------------------------------------------------------------------- */

    function timeToDayID() internal view returns (uint) {
        return block.timestamp / 1 days;
    }
}
