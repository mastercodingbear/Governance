pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./ERC20.sol";
import "./CloneFactory.sol";
import "./OGTokenInterface.sol";
import "./OGDTokenInterface.sol";
import "./Owned.sol";
import "./Staking.sol";
import "./CurveInterface.sol";

// SPDX-License-Identifier: GPLv2
contract StakingFactory is CloneFactory, Owned {
    Staking public stakingTemplate;
    OGTokenInterface public ogToken;
    OGDTokenInterface public ogdToken;
    CurveInterface public stakingRewardCurve;

    mapping(bytes32 => Staking) public stakings;
    bytes32[] public stakingsIndex;
    mapping(Staking => bool) public contracts;

    event StakingCreated(bytes32 indexed key, Staking indexed staking);
    event StakingRewardCurveUpdated(CurveInterface indexed stakingRewardCurve);

    constructor(
        OGTokenInterface _ogToken,
        OGDTokenInterface _ogdToken,
        CurveInterface _stakingRewardCurve
    ) {
        initOwned(msg.sender);
        ogToken = _ogToken;
        ogdToken = _ogdToken;
        stakingRewardCurve = _stakingRewardCurve;
        stakingTemplate = new Staking();
    }

    function setStakingRewardCurve(CurveInterface _stakingRewardCurve)
        public
        onlyOwner
    {
        stakingRewardCurve = _stakingRewardCurve;
        emit StakingRewardCurveUpdated(_stakingRewardCurve);
    }

    function getStakingRewardCurve()
        external
        view
        returns (CurveInterface _stakingRewardCurve)
    {
        _stakingRewardCurve = stakingRewardCurve;
    }

    function getStakingByIndex(uint256 i)
        public
        view
        returns (bytes32 key, Staking staking)
    {
        require(i < stakingsIndex.length, "Invalid stakings index");
        key = stakingsIndex[i];
        staking = stakings[key];
    }

    function stakingsLength() public view returns (uint256) {
        return stakingsIndex.length;
    }

    function addStakingForToken(
        uint256 tokens,
        uint256 duration,
        address tokenAddress,
        string memory name
    ) external returns (Staking staking) {
        return
            _staking(
                tokens,
                duration,
                1,
                [tokenAddress, address(0), address(0), address(0)],
                [
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0)
                ],
                [name, "", "", ""]
            );
    }

    function addStakeForFeed(
        uint256 tokens,
        uint256 duration,
        address feedAddress,
        uint256 feedType,
        uint256 feedDecimals,
        string memory name
    ) external returns (Staking staking) {
        return
            _staking(
                tokens,
                duration,
                1,
                [feedAddress, address(0), address(0), address(0)],
                [
                    uint256(feedType),
                    uint256(feedDecimals),
                    uint256(0),
                    uint256(0),
                    uint256(0),
                    uint256(0)
                ],
                [name, "", "", ""]
            );
    }

    function _staking(
        uint256 tokens,
        uint256 duration,
        uint256 dataType,
        address[4] memory addresses,
        uint256[6] memory uints,
        string[4] memory strings
    ) internal returns (Staking staking) {
        bytes32 key = keccak256(
            abi.encodePacked(
                dataType,
                addresses,
                uints,
                strings[0],
                strings[1],
                strings[2],
                strings[3]
            )
        );
        staking = stakings[key];
        if (address(staking) == address(0)) {
            staking = Staking(createClone(address(stakingTemplate)));
            staking.initStaking(
                stakingsIndex.length,
                ogToken,
                ogdToken,
                dataType,
                addresses,
                uints,
                strings
            );
            stakings[key] = staking;
            stakingsIndex.push(key);
            contracts[staking] = true;
            emit StakingCreated(key, staking);
        }
        require(
            ogToken.transferFrom(msg.sender, address(staking), tokens),
            "OG transferFrom failed"
        );
        staking.stakeThroughFactory(msg.sender, tokens, duration);
    }

    function setStakingStakingRewardCurve(
        Staking staking,
        CurveInterface _stakingRewardCurve
    ) public onlyOwner {
        staking.setStakingRewardCurve(_stakingRewardCurve);
    }

    function slash(Staking staking, uint256 slashingFactor) public onlyOwner {
        staking.slash(slashingFactor);
    }

    function availableOGTokensToMint() external view returns (uint256 tokens) {
        tokens = ogToken.availableToMint();
    }

    function mintOGTokens(address tokenOwner, uint256 tokens) public {
        require(contracts[Staking(msg.sender)], "Caller not child");
        // console.log("        >   %s -> StakingFactory.mintOGTokens(%s, %s)", msg.sender, tokenOwner, tokens);
        require(ogToken.mint(tokenOwner, tokens), "OG mint failed");
    }

    function mintOGDTokens(address tokenOwner, uint256 tokens) public {
        require(contracts[Staking(msg.sender)], "Caller not child");
        // console.log("        >   %s -> StakingFactory.mintOGDTokens(%s, %s)", msg.sender, tokenOwner, tokens);
        require(ogdToken.mint(tokenOwner, tokens), "OG mint failed");
    }

    function burnFromOGDTokens(address tokenOwner, uint256 tokens) public {
        require(contracts[Staking(msg.sender)], "Caller not child");
        // console.log("        >   %s -> StakingFactory.withdrawDividendsAndBurnOGDTokensFor(tokenOwner %s, tokens %s)", msg.sender, tokenOwner, tokens);
        require(ogdToken.burnFrom(tokenOwner, tokens), "OG burnFrom failed");
        // require(ogdToken.withdrawDividendsFor(tokenOwner, tokenOwner), "OGD withdrawDividendsFor failed");
        // require(ogdToken.transferFrom(tokenOwner, address(0), withdrawTokens), "OGD transfer failed");
    }

    // function addStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    //     bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, strings[0], strings[1], strings[2], strings[3]));
    //     StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    //     if (stakeInfo.dataType == 0) {
    //         stakeInfoData[stakingKey] = StakeInfo(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    //         stakeInfoIndex.push(stakingKey);
    //         emit StakeInfoAdded(stakingKey, dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    //     }
    //     _addStake(tokens, stakingKey);
    // }
    // function subStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    //     bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, strings[0], strings[1], strings[2], strings[3]));
    //     _subStake(tokens, stakingKey);
    // }
    // function _addStake(uint tokens, bytes32 stakingKey) internal {
    //     Commitment storage committment = commitments[msg.sender];
    //     require(committment.tokens > 0, "OptinoGov: Commit before staking");
    //     require(committment.tokens >= committment.staked + tokens, "OptinoGov: Insufficient tokens to stake");
    //     committment.staked = committment.staked.add(tokens);
    //     // TODO committment.stakes[stakingKey] = committment.stakes[stakingKey].add(tokens);
    //     // TODO emit Staked(msg.sender, tokens, committment.stakes[stakingKey], stakingKey);
    // }
    // function _subStake(uint tokens, bytes32 stakingKey) internal {
    //     Commitment storage committment = commitments[msg.sender];
    //     require(committment.tokens > 0, "OptinoGov: Commit and stake tokens before unstaking");
    //     // TODO require(committment.stakes[stakingKey] >= tokens, "OptinoGov: Insufficient staked tokens");
    //     committment.staked = committment.staked.sub(tokens);
    //     // TODO committment.stakes[stakingKey] = committment.stakes[stakingKey].sub(tokens);
    //     // TODO emit Unstaked(msg.sender, tokens, committment.stakes[stakingKey], stakingKey);
    // }
}
