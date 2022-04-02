pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./OGTokenInterface.sol";
import "./OGDTokenInterface.sol";
import "./InterestUtils.sol";
import "./CurveInterface.sol";

/// @notice Optino Governance config
contract OptinoGovBase {
    bytes32 private constant KEY_OGTOKEN =
        keccak256(abi.encodePacked("ogToken"));
    bytes32 private constant KEY_OGDTOKEN =
        keccak256(abi.encodePacked("ogdToken"));
    bytes32 private constant KEY_OGREWARDCURVE =
        keccak256(abi.encodePacked("ogRewardCurve"));
    bytes32 private constant KEY_VOTEWEIGHTCURVE =
        keccak256(abi.encodePacked("voteWeightCurve"));
    bytes32 private constant KEY_MAXDURATION =
        keccak256(abi.encodePacked("maxDuration"));
    bytes32 private constant KEY_COLLECTREWARDFORFEE =
        keccak256(abi.encodePacked("collectRewardForFee"));
    bytes32 private constant KEY_COLLECTREWARDFORDELAY =
        keccak256(abi.encodePacked("collectRewardForDelay"));
    bytes32 private constant KEY_PROPOSALCOST =
        keccak256(abi.encodePacked("proposalCost"));
    bytes32 private constant KEY_PROPOSALTHRESHOLD =
        keccak256(abi.encodePacked("proposalThreshold"));
    bytes32 private constant KEY_VOTEREWARD =
        keccak256(abi.encodePacked("voteReward"));
    bytes32 private constant KEY_QUORUM = keccak256(abi.encodePacked("quorum"));
    bytes32 private constant KEY_QUORUMDECAYPERSECOND =
        keccak256(abi.encodePacked("quorumDecayPerSecond"));
    bytes32 private constant KEY_VOTINGDURATION =
        keccak256(abi.encodePacked("votingDuration"));
    bytes32 private constant KEY_EXECUTEDELAY =
        keccak256(abi.encodePacked("executeDelay"));

    OGTokenInterface public ogToken;
    OGDTokenInterface public ogdToken;
    CurveInterface public ogRewardCurve;
    CurveInterface public voteWeightCurve;
    uint256 public maxDuration = 10000 seconds; // Testing 365 days;
    uint256 public collectRewardForFee = 5e16; // 5%, 18 decimals
    uint256 public collectRewardForDelay = 1 seconds; // Testing 7 days
    uint256 public proposalCost = 100e18; // 100 tokens assuming 18 decimals
    uint256 public proposalThreshold = 1e15; // 0.1%, 18 decimals
    uint256 public voteReward = 1e15; // 0.1% of weightedVote
    uint256 public quorum = 2e17; // 20%, 18 decimals
    uint256 public quorumDecayPerSecond = 4e17 / uint256(365 days); // 40% per year, i.e., 0 in 6 months
    uint256 public votingDuration = 10 seconds; // 3 days;
    uint256 public executeDelay = 10 seconds; // 2 days;

    event ConfigUpdated(string key, uint256 value);

    modifier onlySelf() {
        require(msg.sender == address(this), "Not self");
        _;
    }

    constructor(
        OGTokenInterface _ogToken,
        OGDTokenInterface _ogdToken,
        CurveInterface _ogRewardCurve,
        CurveInterface _voteWeightCurve
    ) {
        ogToken = _ogToken;
        ogdToken = _ogdToken;
        ogRewardCurve = _ogRewardCurve;
        voteWeightCurve = _voteWeightCurve;
    }

    function setConfig(string memory key, uint256 value) external onlySelf {
        bytes32 _key = keccak256(abi.encodePacked(key));
        /*if (_key == KEY_OGTOKEN) {
            ogToken = OGTokenInterface(address(value));
        } else if (_key == KEY_VOTEWEIGHTCURVE) {
            ogdToken = OGDTokenInterface(address(value));
        } else*/
        if (_key == KEY_OGREWARDCURVE) {
            ogRewardCurve = CurveInterface(address(uint160(value)));
        } else if (_key == KEY_VOTEWEIGHTCURVE) {
            voteWeightCurve = CurveInterface(address(uint160(value)));
        } else if (_key == KEY_MAXDURATION) {
            require(maxDuration < 5 * 365 days); // Cannot exceed 5 years
            maxDuration = value;
        } else if (_key == KEY_COLLECTREWARDFORFEE) {
            require(collectRewardForFee < 1e18); // Cannot exceed 100%
            collectRewardForFee = value;
        } else if (_key == KEY_COLLECTREWARDFORDELAY) {
            collectRewardForDelay = value;
        } else if (_key == KEY_PROPOSALCOST) {
            proposalCost = value;
        } else if (_key == KEY_PROPOSALTHRESHOLD) {
            proposalThreshold = value;
        } else if (_key == KEY_VOTEREWARD) {
            voteReward = value;
        } else if (_key == KEY_QUORUM) {
            quorum = value;
        } else if (_key == KEY_QUORUMDECAYPERSECOND) {
            quorumDecayPerSecond = value;
        } else if (_key == KEY_VOTINGDURATION) {
            votingDuration = value;
        } else if (_key == KEY_EXECUTEDELAY) {
            executeDelay = value;
        } else {
            revert(); // Invalid key
        }
        emit ConfigUpdated(key, value);
    }

    // ------------------------------------------------------------------------
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // The signature format is a compact form {bytes32 r}{bytes32 s}{uint8 v}.
    // Compact means, uint8 is not padded to 32 bytes.
    //
    // An invalid signature results in the address(0) being returned, make
    // sure that the returned result is checked to be non-zero for validity
    //
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(bytes32 hash, bytes memory sig)
        public
        pure
        returns (address recoveredAddress)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP, one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change, see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

/// @notice Optino Governance. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OptinoGov is ERC20, OptinoGovBase, InterestUtils {
    struct Account {
        uint64 duration;
        uint64 end;
        uint64 lastDelegated;
        uint64 lastVoted;
        uint64 index;
        address delegatee;
        uint256 rate;
        uint256 balance;
        uint256 votes;
        uint256 delegatedVotes;
    }
    struct Proposal {
        uint64 start;
        uint32 executed;
        address proposer;
        string description;
        address[] targets;
        uint256[] values;
        bytes[] data;
        uint256 forVotes;
        uint256 againstVotes;
    }

    string private constant NAME = "OptinoGov";
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 private constant EIP712_VOTE_TYPEHASH =
        keccak256("Vote(uint256 id,bool support)");
    bytes32 private immutable EIP712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(NAME)),
                getChainId(),
                address(this)
            )
        );

    uint256 private _totalSupply;
    mapping(address => Account) private accounts;
    address[] public accountsIndex;
    uint256 public totalVotes;
    Proposal[] private proposals;
    mapping(uint256 => mapping(address => bool)) public voted;

    event DelegateUpdated(
        address indexed oldDelegatee,
        address indexed delegatee,
        uint256 votes
    );
    event Committed(
        address indexed user,
        uint256 tokens,
        uint256 balance,
        uint256 duration,
        uint256 end,
        address delegatee,
        uint256 votes,
        uint256 totalVotes
    );
    event Recommitted(
        address indexed user,
        uint256 elapsed,
        uint256 reward,
        uint256 callerReward,
        uint256 balance,
        uint256 duration,
        uint256 end,
        uint256 votes,
        uint256 totalVotes
    );
    event Uncommitted(
        address indexed user,
        uint256 tokens,
        uint256 reward,
        uint256 balance,
        uint256 duration,
        uint256 end,
        uint256 votes,
        uint256 totalVotes
    );
    event Proposed(
        address indexed proposer,
        uint256 id,
        string description,
        address[] targets,
        uint256[] value,
        bytes[] data,
        uint256 start
    );
    event Voted(
        address indexed user,
        uint256 id,
        bool support,
        uint256 votes,
        uint256 forVotes,
        uint256 againstVotes
    );
    event Executed(address indexed user, uint256 id);

    constructor(
        OGTokenInterface ogToken,
        OGDTokenInterface ogdToken,
        CurveInterface ogRewardCurve,
        CurveInterface voteWeightCurve
    ) OptinoGovBase(ogToken, ogdToken, ogRewardCurve, voteWeightCurve) {}

    function symbol() external pure override returns (string memory) {
        return NAME;
    }

    function name() external pure override returns (string memory) {
        return NAME;
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

    function delegate(address delegatee) public {
        require(
            delegatee == address(0) || accounts[delegatee].end != 0,
            "delegatee not registered"
        );
        require(msg.sender != delegatee, "Cannot delegate to self");
        Account storage account = accounts[msg.sender];
        require(
            uint256(account.lastVoted) + votingDuration < block.timestamp,
            "Cannot delegate after recent vote"
        );
        require(
            uint256(account.lastDelegated) + votingDuration < block.timestamp,
            "Cannot vote after recent delegation"
        );
        address oldDelegatee = account.delegatee;
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes -= account.votes;
        }
        account.delegatee = delegatee;
        account.lastDelegated = uint64(block.timestamp);
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes += account.votes;
        }
        emit DelegateUpdated(oldDelegatee, delegatee, account.votes);
    }

    function updateStatsBefore(Account storage account) internal {
        totalVotes -= account.votes;
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes -= account.votes;
        }
    }

    function updateStatsAfter(Account storage account) internal {
        uint256 rate = voteWeightCurve.getRate(uint256(account.duration));
        account.votes = (account.balance * rate) / 1e18;
        totalVotes += account.votes;
        if (account.delegatee != address(0)) {
            accounts[account.delegatee].delegatedVotes += account.votes;
        }
    }

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

    function _getOGRewardRate(uint256 term)
        internal
        view
        returns (uint256 rate)
    {
        try ogRewardCurve.getRate(term) returns (uint256 _rate) {
            rate = _rate;
        } catch {
            rate = 0;
        }
    }

    // commit(tokens, duration) - tokens can be 0 for a recommit, duration can be 0
    // uncommit(tokens) - tokens can be 0 to uncommit all
    // uncommitFor(tokens) by different msg.sender for a %fee, only after may need a time delay
    function _changeCommitment(
        address tokenOwner,
        uint256 depositTokens,
        uint256 withdrawTokens,
        bool withdrawRewards,
        uint256 duration
    ) internal {
        Account storage account = accounts[tokenOwner];
        if (depositTokens > 0) {
            require(duration > 0, "Duration must be > 0");
        }
        if (withdrawTokens > 0) {
            require(
                uint256(account.end) < block.timestamp,
                "Commitment still active"
            );
            require(withdrawTokens <= account.balance, "Unsufficient balance");
        }
        updateStatsBefore(account);
        (uint256 reward, uint256 elapsed) = _calculateReward(account);
        uint256 availableToMint = ogToken.availableToMint();
        if (reward > availableToMint) {
            reward = availableToMint;
        }
        uint256 callerReward;
        if (reward > 0) {
            if (withdrawRewards) {
                require(ogToken.mint(tokenOwner, reward), "OG mint failed");
            } else {
                if (msg.sender != tokenOwner) {
                    callerReward = (reward * collectRewardForFee) / 1e18;
                    if (callerReward > 0) {
                        reward -= callerReward;
                        require(
                            ogToken.mint(msg.sender, callerReward),
                            "OG mint failed"
                        );
                    }
                }
                require(ogToken.mint(address(this), reward), "OG mint failed");
                account.balance += reward;
                _totalSupply += reward;
                require(ogdToken.mint(tokenOwner, reward), "OGD mint failed");
                emit Transfer(address(0), tokenOwner, reward);
            }
        }
        if (depositTokens > 0) {
            if (account.end == 0) {
                uint256 rate = _getOGRewardRate(duration);
                accounts[tokenOwner] = Account(
                    uint64(duration),
                    uint64(block.timestamp + duration),
                    uint64(0),
                    uint64(0),
                    uint64(accountsIndex.length),
                    address(0),
                    rate,
                    depositTokens,
                    0,
                    0
                );
                account = accounts[tokenOwner];
                accountsIndex.push(tokenOwner);
            } else {
                require(
                    block.timestamp + duration >= account.end,
                    "Cannot shorten duration"
                );
                account.duration = uint64(duration);
                account.end = uint64(block.timestamp + duration);
                account.rate = _getOGRewardRate(duration);
                account.balance += depositTokens;
            }
            require(
                ogdToken.mint(tokenOwner, depositTokens),
                "OGD mint failed"
            );
            // TODO account.votes not updated. remove remaining variables
            _totalSupply += depositTokens;
            emit Transfer(address(0), tokenOwner, depositTokens);
        } else if (withdrawTokens > 0) {
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
            // TODO: Check
            account.duration = uint64(0);
            account.end = uint64(block.timestamp);
            require(
                ogdToken.burnFrom(tokenOwner, withdrawTokens),
                "OG burnFrom failed"
            );
            require(
                ogToken.transfer(tokenOwner, withdrawTokens),
                "OG transfer failed"
            );
        } else {
            // require(block.timestamp + duration >= account.end, "Cannot shorten duration");
            account.duration = uint64(duration);
            account.end = uint64(block.timestamp + duration);
        }
        updateStatsAfter(account);
        if (depositTokens > 0) {
            emit Committed(
                tokenOwner,
                depositTokens,
                account.balance,
                account.duration,
                account.end,
                account.delegatee,
                account.votes,
                totalVotes
            );
        } else if (withdrawTokens > 0) {
            emit Uncommitted(
                tokenOwner,
                withdrawTokens,
                reward,
                account.balance,
                account.duration,
                account.end,
                account.votes,
                totalVotes
            );
        } else {
            emit Recommitted(
                tokenOwner,
                elapsed,
                reward,
                callerReward,
                account.balance,
                account.duration,
                account.end,
                account.votes,
                totalVotes
            );
        }
    }

    function commit(uint256 tokens, uint256 duration) public {
        // require(duration > 0, "duration must be > 0");
        require(
            ogToken.transferFrom(msg.sender, address(this), tokens),
            "OG transferFrom failed"
        );
        _changeCommitment(msg.sender, tokens, 0, false, duration);
    }

    function uncommit(uint256 tokens) public {
        if (tokens == 0) {
            tokens = accounts[msg.sender].balance;
            uint256 ogdTokens = ogdToken.balanceOf(msg.sender);
            if (ogdTokens < tokens) {
                tokens = ogdTokens;
            }
        }
        require(accounts[msg.sender].balance > 0, "No balance to uncommit");
        _changeCommitment(
            msg.sender,
            0,
            tokens,
            tokens == accounts[msg.sender].balance,
            0
        );
        emit Transfer(msg.sender, address(0), tokens);
    }

    function uncommitFor(address tokenOwner) public {
        require(
            accounts[tokenOwner].balance > 0,
            "tokenOwner has no balance to uncommit"
        );
        _changeCommitment(tokenOwner, 0, 0, false, 0);
    }

    function propose(
        string memory description,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data
    ) public returns (uint256) {
        // console.log("        > %s -> propose(description %s)", msg.sender, description);
        // require(accounts[msg.sender].votes >= totalVotes.mul(proposalThreshold).div(1e18), "OptinoGov: Not enough votes to propose");
        require(
            targets.length > 0 &&
                values.length == targets.length &&
                data.length == targets.length,
            "Invalid data"
        );
        Proposal storage proposal = proposals.push();
        proposal.start = uint64(block.timestamp);
        // proposal.executed = 0;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.targets = targets;
        proposal.values = values;
        proposal.data = data;
        // proposal.forVotes = 0;
        // proposal.againstVotes = 0;
        require(ogToken.burnFrom(msg.sender, proposalCost), "OG burn failed");
        emit Proposed(
            msg.sender,
            proposals.length - 1,
            description,
            proposal.targets,
            proposal.values,
            proposal.data,
            block.timestamp
        );
        return proposals.length - 1;
    }

    function getProposal(uint256 i)
        public
        view
        returns (
            uint64 start,
            uint32 executed,
            address proposer,
            string memory description,
            address[] memory targets,
            uint256[] memory _values,
            bytes[] memory data,
            uint256 forVotes,
            uint256 againstVotes
        )
    {
        require(i < proposals.length, "Invalid index");
        Proposal memory proposal = proposals[i];
        return (
            proposal.start,
            proposal.executed,
            proposal.proposer,
            proposal.description,
            proposal.targets,
            proposal.values,
            proposal.data,
            proposal.forVotes,
            proposal.againstVotes
        );
    }

    function proposalsLength() public view returns (uint256) {
        return proposals.length;
    }

    function vote(uint256 id, bool support) public {
        _vote(msg.sender, id, support);
    }

    function _vote(
        address voter,
        uint256 id,
        bool support
    ) internal {
        Proposal storage proposal = proposals[id];
        require(
            proposal.start != 0 &&
                block.timestamp < uint256(proposal.start) + votingDuration,
            "Voting closed"
        );
        require(
            accounts[voter].lastDelegated + votingDuration < block.timestamp,
            "Cannot vote after recent delegation"
        );
        require(!voted[id][voter], "Already voted");
        uint256 votes = accounts[voter].votes + accounts[voter].delegatedVotes;
        if (accounts[voter].delegatee != address(0)) {
            if (support) {
                proposal.forVotes += votes;
            } else {
                proposal.againstVotes += votes;
            }
            uint256 _voteReward = (accounts[voter].votes * voteReward) / 1e18;
            if (_voteReward > 0) {
                require(ogToken.mint(voter, _voteReward), "OG mint failed");
            }
        }
        voted[id][voter] = true;
        accounts[voter].lastVoted = uint64(block.timestamp);
        emit Voted(
            voter,
            id,
            support,
            votes,
            proposal.forVotes,
            proposal.againstVotes
        );
    }

    function voteDigest(uint256 id, bool support)
        public
        view
        returns (bytes32 digest)
    {
        bytes32 structHash = keccak256(
            abi.encode(EIP712_VOTE_TYPEHASH, id, support)
        );
        digest = keccak256(
            abi.encodePacked("\x19\x01", EIP712_DOMAIN_SEPARATOR, structHash)
        );
    }

    function voteBySigs(uint256 id, bytes[] memory sigs) public {
        for (uint256 i = 0; i < sigs.length; i++) {
            bytes memory sig = sigs[i];
            bytes32 digest = voteDigest(id, true);
            address voter = ecrecoverFromSig(digest, sig);
            if (voter != address(0) && accounts[voter].balance > 0) {
                if (!voted[id][voter]) {
                    _vote(voter, id, true);
                }
            } else {
                digest = voteDigest(id, false);
                voter = ecrecoverFromSig(digest, sig);
                if (voter != address(0) && accounts[voter].balance > 0) {
                    if (!voted[id][voter]) {
                        _vote(voter, id, false);
                    }
                }
            }
        }
    }

    // TODO
    function execute(uint256 id) public {
        Proposal storage proposal = proposals[id];
        // require(proposal.start != 0 && block.timestamp >= proposal.start.add(votingDuration).add(executeDelay));

        // if (quorum > currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks)) {
        //     return quorum.sub(currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks));
        // } else {
        //     return 0;
        // }

        // require(proposal.forVotes >= totalVotes.mul(quorum).div(1e18), "OptinoGov: Not enough votes to execute");
        proposal.executed = 1;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            (bool success, ) = proposal.targets[i].call{
                value: proposal.values[i]
            }(proposal.data[i]);
            require(success, "Execution failed");
        }

        emit Executed(msg.sender, id);
    }

    receive() external payable {
        // TODO depositDividend(address(0), msg.value);
    }
}
