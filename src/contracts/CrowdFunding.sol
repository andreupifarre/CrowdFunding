// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// import "hardhat/console.sol";

contract CrowdFunding is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public token;
    Campaign[] public campaigns;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address token_) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        token = IERC20Upgradeable(token_);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    event CampaignCreated(
        address pledgee,
        uint256 target,
        uint256 deadline,
        uint256 currentTimestamp
    );

    event Pledged(address pledger, uint256 campaignId, uint256 amount);
    event Withdrew(address pledgee, uint256 campaignId, uint256 amount);
    event Refunded(address pledgee, uint256 campaignId, uint256 amount);

    struct Campaign {
        address pledgee; // The address of the campaign creator
        uint256 target; // The target amount to raise in wei
        uint256 deadline; // The deadline timestamp for the campaign
        uint256 raised; // The amount raised so far in wei
        mapping(address => uint256) pledges; // A mapping of pledgers and their pledged amounts
    }

    modifier onlyPledger(uint256 campaignId) {
        require(
            campaigns[campaignId].pledges[msg.sender] > 0,
            "You are not a pledger"
        );
        _;
    }

    modifier onlyPledgee(uint256 campaignId) {
        require(
            campaigns[campaignId].pledgee == msg.sender,
            "You are not the pledgee"
        );
        _;
    }

    function getPledged(uint256 campaignId) public view returns (uint256) {
        return campaigns[campaignId].pledges[msg.sender];
    }

    function createCampaign(uint256 target, uint256 deadline) public {
        require(target > 0, "Target must be positive");
        require(deadline > 0, "Deadline must be positive");

        // block.timestamp can be manipulated by miners.
        uint256 currentTimestamp = block.timestamp;
        require(deadline > currentTimestamp, "Deadline must be in the future");

        Campaign storage campaign = campaigns.push();
        campaign.pledgee = msg.sender;
        campaign.target = target;
        campaign.deadline = deadline;
        campaign.raised = 0;

        emit CampaignCreated(msg.sender, target, deadline, currentTimestamp);
    }

    function pledge(uint256 campaignId, uint256 amount) public {
        Campaign storage campaign = campaigns[campaignId];
        // block.timestamp can be manipulated by miners. Could be improved with:
        // require(block.number < getDeadlineBlockNumber(), "The deadline has passed");
        require(block.timestamp < campaign.deadline, "The deadline has passed");
        require(amount > 0, "Pledge amount must be positive");

        campaign.pledges[msg.sender] += amount;
        campaign.raised += amount;

        emit Pledged(msg.sender, campaignId, amount);

        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 campaignId) public onlyPledgee(campaignId) {
        Campaign storage campaign = campaigns[campaignId];

        require(
            campaign.raised >= campaign.target,
            "The campaign has not reached its target"
        );

        // block.timestamp can be manipulated by miners.
        require(
            campaign.deadline <= block.timestamp,
            "The deadline has not yet passed"
        );

        uint256 amount = campaign.raised;

        campaign.raised = 0;

        emit Withdrew(msg.sender, campaignId, amount);

        token.safeTransfer(msg.sender, amount);
    }

    function refund(uint256 campaignId) public onlyPledger(campaignId) {
        Campaign storage campaign = campaigns[campaignId];

        require(
            campaign.raised < campaign.target,
            "The campaign has reached its target"
        );

        // block.timestamp can be manipulated by miners.
        require(
            campaign.deadline <= block.timestamp,
            "The deadline has not yet passed"
        );

        uint256 amount = campaign.pledges[msg.sender];

        campaign.pledges[msg.sender] = 0;

        emit Refunded(msg.sender, campaignId, amount);

        token.safeTransfer(msg.sender, amount);
    }
}
