pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./OGTokenInterface.sol";
import "./OGDTokenInterface.sol";
import "./StakingFactoryInterface.sol";
import "./Owned.sol";
import "./InterestUtils.sol";
import "./CurveInterface.sol";

// SPDX-License-Identifier: GPLv2
contract Staking is ERC20, Owned, InterestUtils {
    // Contracts { dataType 0, address contractAddress, string name }
    // Token { dataType 1, address tokenAddress }
    // Feed { dataType 2, address feedAddress, uint feedType, uint feedDecimals, string name }
    // Conventions { dataType 3, address [token0, token1], address [feed0, feed1], uint[6] [type0, type1, decimals0, decimals1, inverse0, inverse1], string [feed0Name, feedName2, Market, Convention] }
    // General { dataType 4, address[4] addresses, address [feed0, feed1], uint[6] uints, string[4] strings }
    struct StakingInfo {
        uint256 dataType;
        address[4] addresses;
        uint256[6] uints;
        string string0; // TODO: Check issues using string[4] strings
        string string1;
        string string2;
        string string3;
    }

    struct Account {
        uint64 duration;
        uint64 end;
        uint64 index;
        uint256 rate; // max uint64 = 18_446744073_709551615 = 1800%
        uint256 balance;
    }

    bytes constant SYMBOLPREFIX = "OGS";
    uint8 constant DASH = 45;
    uint8 constant ZERO = 48;
    uint256 constant MAXSTAKINGINFOSTRINGLENGTH = 8;

    uint256 public id;
    OGTokenInterface public ogToken;
    OGDTokenInterface public ogdToken;
    CurveInterface public stakingRewardCurve;
    StakingInfo public stakingInfo;

    uint256 _totalSupply;
    mapping(address => Account) public accounts;
    address[] public accountsIndex;

    uint256 public weightedEndNumerator;
    // uint public weightedDurationDenominator;
    uint256 public slashingFactor;

    event StakingRewardCurveUpdated(CurveInterface indexed stakingRewardCurve);
    event Staked(
        address indexed tokenOwner,
        uint256 tokens,
        uint256 duration,
        uint256 end
    );
    event Unstaked(
        address indexed tokenOwner,
        uint256 tokens,
        uint256 reward,
        uint256 tokensWithSlashingFactor,
        uint256 rewardWithSlashingFactor
    );
    event Slashed(uint256 slashingFactor, uint256 tokensBurnt);

    constructor() {}

    function initStaking(
        uint256 _id,
        OGTokenInterface _ogToken,
        OGDTokenInterface _ogdToken,
        uint256 dataType,
        address[4] memory addresses,
        uint256[6] memory uints,
        string[4] memory strings
    ) public {
        initOwned(msg.sender);
        id = _id;
        ogToken = _ogToken;
        ogdToken = _ogdToken;
        stakingRewardCurve = CurveInterface(address(0));
        stakingInfo = StakingInfo(
            dataType,
            addresses,
            uints,
            strings[0],
            strings[1],
            strings[2],
            strings[3]
        );
    }

    function symbol() external view override returns (string memory _symbol) {
        bytes memory b = new bytes(7 + SYMBOLPREFIX.length);
        uint256 i;
        uint256 j;
        uint256 num;
        for (i = 0; i < SYMBOLPREFIX.length; i++) {
            b[j++] = SYMBOLPREFIX[i];
        }
        i = 7;
        do {
            i--;
            num = id / 10**i;
            b[j++] = bytes1(uint8((num % 10) + ZERO));
        } while (i > 0);
        _symbol = string(b);
    }

    function name() external view override returns (string memory) {
        uint256 i;
        uint256 j;
        bytes memory b = new bytes(4 + MAXSTAKINGINFOSTRINGLENGTH);
        for (i = 0; i < SYMBOLPREFIX.length; i++) {
            b[j++] = SYMBOLPREFIX[i];
        }
        b[j++] = bytes1(DASH);
        bytes memory b1 = bytes(stakingInfo.string0);
        for (i = 0; i < b1.length && i < MAXSTAKINGINFOSTRINGLENGTH; i++) {
            b[j++] = b1[i];
        }
        return string(b);
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply - accounts[address(0)].balance;
    }

    function balanceOf(address tokenOwner)
        external
        view
        override
        returns (uint256 balance)
    {
        return accounts[tokenOwner].balance;
    }

    function transfer(address to, uint256 tokens)
        external
        override
        returns (bool success)
    {
        require(false, "Unimplemented");
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        external
        override
        returns (bool success)
    {
        require(false, "Unimplemented");
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external override returns (bool success) {
        require(false, "Unimplemented");
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(
        address, /*tokenOwner*/
        address /*spender*/
    ) external pure override returns (uint256 remaining) {
        return 0;
    }

    function setStakingRewardCurve(CurveInterface _stakingRewardCurve)
        public
        onlyOwner
    {
        stakingRewardCurve = _stakingRewardCurve;
        emit StakingRewardCurveUpdated(_stakingRewardCurve);
    }

    function _getRate(uint256 term) internal view returns (uint256 rate) {
        if (stakingRewardCurve == CurveInterface(address(0))) {
            try
                StakingFactoryInterface(owner).getStakingRewardCurve().getRate(
                    term
                )
            returns (uint256 _rate) {
                rate = _rate;
            } catch {
                rate = 0;
            }
        } else {
            try stakingRewardCurve.getRate(term) returns (uint256 _rate) {
                rate = _rate;
            } catch {
                rate = 0;
            }
        }
    }

    function getRate(uint256 term) external view returns (uint256 rate) {
        rate = _getRate(term);
    }

    function getStakingInfo()
        public
        view
        returns (
            uint256 dataType,
            address[4] memory addresses,
            uint256[6] memory uints,
            string memory string0,
            string memory string1,
            string memory string2,
            string memory string3
        )
    {
        (dataType, addresses, uints) = (
            stakingInfo.dataType,
            stakingInfo.addresses,
            stakingInfo.uints
        );
        string0 = stakingInfo.string0;
        string1 = stakingInfo.string1;
        string2 = stakingInfo.string2;
        string3 = stakingInfo.string3;
    }

    function getAccountByIndex(uint256 i)
        public
        view
        returns (address tokenOwner, Account memory account)
    {
        require(i < accountsIndex.length, "Invalid index");
        tokenOwner = accountsIndex[i];
        account = accounts[tokenOwner];
    }

    function accountsLength() public view returns (uint256) {
        return accountsIndex.length;
    }

    function weightedEnd() public view returns (uint256 _weightedEnd) {
        if (_totalSupply > 0) {
            _weightedEnd =
                weightedEndNumerator /
                (_totalSupply - accounts[address(0)].balance);
        }
        if (_weightedEnd < block.timestamp) {
            _weightedEnd = block.timestamp;
        }
    }

    // function computeWeight(Account memory account) internal pure returns (uint _weight) {
    //     _weight = account.balance.mul(account.duration).div(365 days);
    // }
    function updateStatsBefore(Account memory account, address tokenOwner)
        internal
    {
        weightedEndNumerator =
            weightedEndNumerator -
            uint256(account.end) *
            (tokenOwner == address(0) ? 0 : account.balance);
        // uint weightedDuration = computeWeight(account);
        // console.log("        > updateStatsBefore(%s).weightedDuration: ", tokenOwner, weightedDuration);
        // weightedDurationDenominator = weightedDurationDenominator.sub(weightedDuration);
    }

    function updateStatsAfter(Account memory account, address tokenOwner)
        internal
    {
        weightedEndNumerator =
            weightedEndNumerator +
            uint256(account.end) *
            (tokenOwner == address(0) ? 0 : account.balance);
        // uint weightedDuration = computeWeight(account);
        // console.log("        > updateStatsAfter(%s).weightedDuration: ", tokenOwner, weightedDuration);
        // weightedDurationDenominator = weightedDurationDenominator.add(weightedDuration);
    }

    // function _stake(address tokenOwner, uint tokens, uint duration) internal {
    //     require(slashingFactor == 0, "Cannot stake if already slashed");
    //     require(duration > 0, "Invalid duration");
    //     Account storage account = accounts[tokenOwner];
    //     updateStatsBefore(account, tokenOwner);
    //     if (account.end == 0) {
    //         console.log("        > _stake(%s) - rewardsPerYear %s", tokenOwner, rewardsPerYear);
    //         accounts[tokenOwner] = Account(uint64(duration), uint64(block.timestamp.add(duration)), uint64(accountsIndex.length), uint64(rewardsPerYear), tokens);
    //         account = accounts[tokenOwner];
    //         accountsIndex.push(tokenOwner);
    //         emit Staked(tokenOwner, tokens, duration, account.end);
    //     } else {
    //         require(block.timestamp + duration >= account.end, "Cannot shorten duration");
    //         _totalSupply = _totalSupply.sub(account.balance);
    //         account.duration = uint64(duration);
    //         account.end = uint64(block.timestamp.add(duration));
    //         account.balance = account.balance.add(tokens);
    //     }
    //     updateStatsAfter(account, tokenOwner);
    //     _totalSupply = _totalSupply.add(account.balance);
    //     emit Transfer(address(0), tokenOwner, tokens);
    // }

    function accruedReward(address tokenOwner)
        public
        view
        returns (uint256 _reward, uint256 _term)
    {
        return _calculateReward(accounts[tokenOwner]);
    }

    function _calculateReward(Account memory account)
        internal
        view
        returns (uint256 _reward, uint256 _term)
    {
        uint256 from = account.end == 0
            ? block.timestamp
            : uint256(account.end) - uint256(account.duration);
        uint256 futureValue = InterestUtils.futureValue(
            account.balance,
            from,
            block.timestamp,
            account.rate
        );
        _reward = futureValue - account.balance;
        _term = block.timestamp - from;
    }

    function _changeStake(
        address tokenOwner,
        uint256 depositTokens,
        uint256 withdrawTokens,
        bool withdrawRewards,
        uint256 duration
    ) internal {
        // console.log("        >   _changeStake(tokenOwner %s, depositTokens %s, withdrawTokens %s,", tokenOwner, depositTokens, withdrawTokens);
        // console.log("              withdrawRewards %s, duration %s)", withdrawRewards, duration);
        Account storage account = accounts[tokenOwner];

        // stakeThroughFactory(...), stake(tokens, duration) or restake(duration)
        if ((depositTokens == 0 && withdrawTokens == 0) || depositTokens > 0) {
            require(slashingFactor == 0, "Cannot stake if already slashed");
            require(duration > 0, "Duration must be > 0");
        }
        // unstake(tokens) or unstakeAll()
        if (withdrawTokens > 0) {
            require(
                uint256(account.end) < block.timestamp,
                "Staking period still active"
            );
            require(
                withdrawTokens <= account.balance,
                "Unsufficient staked balance"
            );
        }
        updateStatsBefore(account, tokenOwner);
        (
            uint256 reward, /*uint term*/

        ) = _calculateReward(account);
        uint256 rewardWithSlashingFactor;
        uint256 availableToMint = StakingFactoryInterface(owner)
            .availableOGTokensToMint();
        if (reward > availableToMint) {
            reward = availableToMint;
        }
        if (withdrawRewards) {
            if (reward > 0) {
                rewardWithSlashingFactor =
                    reward -
                    (reward * slashingFactor) /
                    1e18;
                StakingFactoryInterface(owner).mintOGTokens(
                    tokenOwner,
                    rewardWithSlashingFactor
                );
            }
        } else {
            if (reward > 0) {
                StakingFactoryInterface(owner).mintOGTokens(
                    address(this),
                    reward
                );
                account.balance += reward;
                _totalSupply += reward;
                StakingFactoryInterface(owner).mintOGDTokens(
                    tokenOwner,
                    reward
                );
                emit Transfer(address(0), tokenOwner, reward);
            }
        }
        if ((depositTokens == 0 && withdrawTokens == 0) || depositTokens > 0) {
            if (account.end == 0) {
                uint256 rate = _getRate(duration);
                accounts[tokenOwner] = Account(
                    uint64(duration),
                    uint64(block.timestamp + duration),
                    uint64(accountsIndex.length),
                    rate,
                    depositTokens
                );
                account = accounts[tokenOwner];
                accountsIndex.push(tokenOwner);
                emit Staked(tokenOwner, depositTokens, duration, account.end);
            } else {
                require(
                    block.timestamp + duration >= account.end,
                    "Cannot shorten duration"
                );
                account.duration = uint64(duration);
                account.end = uint64(block.timestamp + duration);
                account.rate = _getRate(duration);
                account.balance += depositTokens;
            }
            if (depositTokens > 0) {
                StakingFactoryInterface(owner).mintOGDTokens(
                    tokenOwner,
                    depositTokens
                );
                _totalSupply += depositTokens;
                emit Transfer(address(0), tokenOwner, depositTokens);
            }
        }
        if (withdrawTokens > 0) {
            _totalSupply -= withdrawTokens;
            account.balance -= withdrawTokens;
            if (account.balance == 0) {
                uint256 removedIndex = uint256(account.index);
                uint256 lastIndex = accountsIndex.length - 1;
                address lastAccountAddress = accountsIndex[lastIndex];
                accountsIndex[removedIndex] = lastAccountAddress;
                accounts[lastAccountAddress].index = uint64(removedIndex);
                delete accountsIndex[lastIndex];
                delete accounts[tokenOwner];
                if (accountsIndex.length > 0) {
                    accountsIndex.pop();
                }
            }
            account.duration = uint64(0);
            account.end = uint64(block.timestamp);
            StakingFactoryInterface(owner).burnFromOGDTokens(
                tokenOwner,
                withdrawTokens
            );
            uint256 tokensWithSlashingFactor = withdrawTokens -
                (withdrawTokens * slashingFactor) /
                1e18;
            require(
                ogToken.transfer(tokenOwner, tokensWithSlashingFactor),
                "OG transfer failed"
            );
            emit Unstaked(
                msg.sender,
                withdrawTokens,
                reward,
                tokensWithSlashingFactor,
                rewardWithSlashingFactor
            );
        }
        updateStatsAfter(account, tokenOwner);
    }

    function stakeThroughFactory(
        address tokenOwner,
        uint256 tokens,
        uint256 duration
    ) public onlyOwner {
        require(tokens > 0, "tokens must be > 0");
        _changeStake(tokenOwner, tokens, 0, false, duration);
    }

    function stake(uint256 tokens, uint256 duration) public {
        require(tokens > 0, "tokens must be > 0");
        require(
            ogToken.transferFrom(msg.sender, address(this), tokens),
            "OG transferFrom failed"
        );
        _changeStake(msg.sender, tokens, 0, false, duration);
    }

    function restake(uint256 duration) public {
        require(accounts[msg.sender].balance > 0, "No balance to restake");
        _changeStake(msg.sender, 0, 0, false, duration);
    }

    function unstake(uint256 tokens) public {
        if (tokens == 0) {
            tokens = accounts[msg.sender].balance;
            uint256 ogdTokens = ogdToken.balanceOf(msg.sender);
            if (ogdTokens < tokens) {
                tokens = ogdTokens;
            }
        }
        require(
            accounts[msg.sender].balance >= tokens,
            "Insufficient tokens to unstake"
        );
        _changeStake(
            msg.sender,
            0,
            tokens,
            tokens == accounts[msg.sender].balance,
            0
        );
        emit Transfer(msg.sender, address(0), tokens);
    }

    function slash(uint256 _slashingFactor) public onlyOwner {
        require(_slashingFactor <= 1e18, "Cannot slash more than 100%");
        require(slashingFactor == 0, "Cannot slash more than once");
        slashingFactor = _slashingFactor;
        uint256 tokensToBurn = (_totalSupply * slashingFactor) / 1e18;
        require(ogToken.burn(tokensToBurn), "OG burn failed");
        emit Slashed(_slashingFactor, tokensToBurn);
    }
}

/*
function addStakeForToken(uint tokens, address tokenAddress, string memory name) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(tokenAddress, name));
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    if (stakeInfo.dataType == 0) {
        stakeInfoData[stakingKey] = StakeInfo(1, [tokenAddress, address(0), address(0), address(0)], [uint(0), uint(0), uint(0), uint(0), uint(0), uint(0)], name, "", "", "");
        stakeInfoIndex.push(stakingKey);
        emit StakeInfoAdded(stakingKey, 1, [tokenAddress, address(0), address(0), address(0)], [uint(0), uint(0), uint(0), uint(0), uint(0), uint(0)], name, "", "", "");
    }
    _addStake(tokens, stakingKey);
}
function subStakeForToken(uint tokens, address tokenAddress, string calldata name) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(tokenAddress, name));
    _subStake(tokens, stakingKey);
}
function addStakeForFeed(uint tokens, address feedAddress, uint feedType, uint feedDecimals, string calldata name) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(feedAddress, feedType, feedDecimals, name));
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    if (stakeInfo.dataType == 0) {
        stakeInfoData[stakingKey] = StakeInfo(2, [feedAddress, address(0), address(0), address(0)], [uint(feedType), uint(feedDecimals), uint(0), uint(0), uint(0), uint(0)], name, "", "", "");
        stakeInfoIndex.push(stakingKey);
        emit StakeInfoAdded(stakingKey, 2, [feedAddress, address(0), address(0), address(0)], [uint(feedType), uint(feedDecimals), uint(0), uint(0), uint(0), uint(0)], name, "", "", "");
    }
    _addStake(tokens, stakingKey);
}
function subStakeForFeed(uint tokens, address feedAddress, uint feedType, uint feedDecimals, string calldata name) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(feedAddress, feedType, feedDecimals, name));
    _subStake(tokens, stakingKey);
}
function addStakeForConvention(uint tokens, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(addresses, uints, strings[0], strings[1], strings[2], strings[3]));
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    if (stakeInfo.dataType == 0) {
        stakeInfoData[stakingKey] = StakeInfo(3, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
        stakeInfoIndex.push(stakingKey);
        emit StakeInfoAdded(stakingKey, 3, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    }
    _addStake(tokens, stakingKey);
}
function subStakeForConvention(uint tokens, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(addresses, uints, strings[0], strings[1], strings[2], strings[3]));
    _subStake(tokens, stakingKey);
}
function addStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, strings[0], strings[1], strings[2], strings[3]));
    StakeInfo memory stakeInfo = stakeInfoData[stakingKey];
    if (stakeInfo.dataType == 0) {
        stakeInfoData[stakingKey] = StakeInfo(dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
        stakeInfoIndex.push(stakingKey);
        emit StakeInfoAdded(stakingKey, dataType, addresses, uints, strings[0], strings[1], strings[2], strings[3]);
    }
    _addStake(tokens, stakingKey);
}
function subStakeForGeneral(uint tokens, uint dataType, address[4] memory addresses, uint[6] memory uints, string[4] memory strings) external {
    bytes32 stakingKey = keccak256(abi.encodePacked(addresses, dataType, uints, strings[0], strings[1], strings[2], strings[3]));
    _subStake(tokens, stakingKey);
}
function _addStake(uint tokens, bytes32 stakingKey) internal {
    Account storage committment = accounts[msg.sender];
    require(committment.tokens > 0, "OptinoGov: Commit before staking");
    require(committment.tokens >= committment.staked + tokens, "OptinoGov: Insufficient tokens to stake");
    committment.staked = committment.staked.add(tokens);
}
function _subStake(uint tokens, bytes32 stakingKey) internal {
    Account storage committment = accounts[msg.sender];
    require(committment.tokens > 0, "OptinoGov: Commit and stake tokens before unstaking");
    committment.staked = committment.staked.sub(tokens);
}
*/
