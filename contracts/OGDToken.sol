pragma solidity ^0.8.0;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./Permissioned.sol";
import "./OGDTokenInterface.sol";
import "./TokenList.sol";

/// @notice Optino Governance Dividend Token = ERC20 + mint + burn + dividend payment. (c) The Optino Project 2020
// SPDX-License-Identifier: GPLv2
contract OGDToken is OGDTokenInterface, Permissioned {
    using TokenList for TokenList.Data;
    using TokenList for TokenList.Token;

    struct Account {
        uint256 balance;
        mapping(address => uint256) lastDividendPoints;
        mapping(address => uint256) owing;
    }

    string private _symbol;
    string private _name;
    uint8 private _decimals;
    uint256 private _totalSupply;
    mapping(address => Account) private accounts;
    mapping(address => mapping(address => uint256)) private allowed;

    TokenList.Data private dividendTokens;

    uint256 private constant POINT_MULTIPLIER = 10e27;
    mapping(address => uint256) public totalDividendPoints;
    mapping(address => uint256) public unclaimedDividends;

    event UpdateAccountInfo(
        address dividendToken,
        address account,
        uint256 owing,
        uint256 totalOwing,
        uint256 lastDividendPoints,
        uint256 totalDividendPoints,
        uint256 unclaimedDividends
    );
    event DividendDeposited(address indexed token, uint256 tokens);
    event DividendWithdrawn(
        address indexed account,
        address indexed destination,
        address indexed token,
        uint256 tokens
    );

    // Duplicated from the library for ABI generation
    event TokenAdded(address indexed token, bool enabled);
    event TokenRemoved(address indexed token);
    event TokenUpdated(address indexed token, bool enabled);

    constructor(
        string memory __symbol,
        string memory __name,
        uint8 __decimals,
        address tokenOwner,
        uint256 initialSupply
    ) {
        initPermissioned(msg.sender);
        _symbol = __symbol;
        _name = __name;
        _decimals = __decimals;
        accounts[tokenOwner].balance = initialSupply;
        _totalSupply = initialSupply;
        emit Transfer(address(0), tokenOwner, _totalSupply);
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return __totalSupply();
    }

    function __totalSupply() internal view returns (uint256) {
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
        permitted(Roles.TransferTokens, tokens)
        returns (bool success)
    {
        _updateAccount(msg.sender);
        _updateAccount(to);
        accounts[msg.sender].balance -= tokens;
        accounts[to].balance += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens)
        external
        override
        returns (bool success)
    {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    )
        external
        override
        permitted(Roles.TransferTokens, tokens)
        returns (bool success)
    {
        _updateAccount(from);
        _updateAccount(to);
        allowed[from][msg.sender] -= tokens;
        accounts[from].balance -= tokens;
        accounts[to].balance += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function addDividendToken(address _dividendToken)
        external
        permitted(Roles.SetConfig, 0)
    {
        if (!dividendTokens.initialised) {
            dividendTokens.init();
        }
        dividendTokens.add(_dividendToken, true);
    }

    function updateToken(address token, bool enabled)
        public
        permitted(Roles.SetConfig, 0)
    {
        require(dividendTokens.initialised);
        dividendTokens.update(token, enabled);
    }

    function removeToken(address token) public permitted(Roles.SetConfig, 0) {
        require(dividendTokens.initialised);
        dividendTokens.remove(token);
    }

    function getDividendTokenByIndex(uint256 i)
        public
        view
        returns (address, bool)
    {
        require(i < dividendTokens.length(), "Invalid index");
        TokenList.Token memory dividendToken = dividendTokens.entries[
            dividendTokens.index[i]
        ];
        return (dividendToken.token, dividendToken.enabled);
    }

    function dividendTokensLength() public view returns (uint256) {
        return dividendTokens.length();
    }

    /// @notice Dividends owning since the last _updateAccount(...) + new dividends owing since the last _updateAccount(...)
    function dividendsOwing(address account)
        public
        view
        returns (
            address[] memory tokenList,
            uint256[] memory owingList,
            uint256[] memory newOwingList
        )
    {
        tokenList = new address[](dividendTokens.index.length);
        owingList = new uint256[](dividendTokens.index.length);
        newOwingList = new uint256[](dividendTokens.index.length);
        for (uint256 i = 0; i < dividendTokens.index.length; i++) {
            TokenList.Token memory dividendToken = dividendTokens.entries[
                dividendTokens.index[i]
            ];
            tokenList[i] = dividendToken.token;
            owingList[i] = accounts[account].owing[dividendToken.token];
            newOwingList[i] = _newDividendsOwing(dividendToken.token, account);
        }
    }

    /// @notice New dividends owing since the last _updateAccount(...)
    function _newDividendsOwing(address dividendToken, address account)
        internal
        view
        returns (uint256)
    {
        uint256 newDividendPoints = totalDividendPoints[dividendToken] -
            accounts[account].lastDividendPoints[dividendToken];
        return
            (accounts[account].balance * newDividendPoints) / POINT_MULTIPLIER;
    }

    function _updateAccount(address account) internal {
        for (uint256 i = 0; i < dividendTokens.index.length; i++) {
            TokenList.Token memory dividendToken = dividendTokens.entries[
                dividendTokens.index[i]
            ];
            if (dividendToken.enabled) {
                uint256 newOwing = _newDividendsOwing(
                    dividendToken.token,
                    account
                );
                if (newOwing > 0) {
                    unclaimedDividends[dividendToken.token] -= newOwing;
                    accounts[account].owing[dividendToken.token] += newOwing;
                }
                accounts[account].lastDividendPoints[
                    dividendToken.token
                ] = totalDividendPoints[dividendToken.token];
            }
        }
    }

    // function _updateAccounts(address account1, address account2) internal {
    //     for (uint i = 0; i < dividendTokens.index.length; i++) {
    //         TokenList.Token memory dividendToken = dividendTokens.entries[dividendTokens.index[i]];
    //         if (dividendToken.enabled) {
    //             uint newOwing1 = _newDividendsOwing(dividendToken.token, account1);
    //             if (newOwing1 > 0) {
    //                 unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(newOwing1);
    //                 accounts[account1].owing[dividendToken.token] = accounts[account1].owing[dividendToken.token].add(newOwing1);
    //             }
    //             accounts[account1].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
    //             if (account1 != account2) {
    //                 uint newOwing2 = _newDividendsOwing(dividendToken.token, account2);
    //                 if (newOwing2 > 0) {
    //                     unclaimedDividends[dividendToken.token] = unclaimedDividends[dividendToken.token].sub(newOwing2);
    //                     accounts[account2].owing[dividendToken.token] = accounts[account2].owing[dividendToken.token].add(newOwing2);
    //                 }
    //                 accounts[account2].lastDividendPoints[dividendToken.token] = totalDividendPoints[dividendToken.token];
    //             }
    //         }
    //     }
    // }

    /// @notice Deposit enabled dividend token
    function depositDividend(address token, uint256 tokens) public payable {
        TokenList.Token memory _dividendToken = dividendTokens.entries[token];
        require(__totalSupply() > 0, "totalSupply 0");
        require(_dividendToken.enabled, "Dividend token not enabled");
        totalDividendPoints[token] +=
            (tokens * POINT_MULTIPLIER) /
            __totalSupply();
        unclaimedDividends[token] += tokens;
        if (token == address(0)) {
            require(msg.value >= tokens, "Insufficient ETH sent");
            uint256 refund = msg.value - tokens;
            if (refund > 0) {
                require(payable(msg.sender).send(refund), "ETH refund failure");
            }
        } else {
            require(
                ERC20(token).transferFrom(msg.sender, address(this), tokens),
                "ERC20 transferFrom failure"
            );
        }
        emit DividendDeposited(token, tokens);
    }

    /// @notice Received ETH as dividends
    receive() external payable {
        depositDividend(address(0), msg.value);
    }

    function _withdrawDividendsFor(address account, address destination)
        internal
    {
        _updateAccount(account);
        for (uint256 i = 0; i < dividendTokens.index.length; i++) {
            TokenList.Token memory dividendToken = dividendTokens.entries[
                dividendTokens.index[i]
            ];
            if (dividendToken.enabled) {
                uint256 tokens = accounts[account].owing[dividendToken.token];
                if (tokens > 0) {
                    accounts[account].owing[dividendToken.token] = 0;
                    if (dividendToken.token == address(0)) {
                        require(
                            payable(destination).send(tokens),
                            "ETH send failure"
                        );
                    } else {
                        require(
                            ERC20(dividendToken.token).transfer(
                                destination,
                                tokens
                            ),
                            "ERC20 transfer failure"
                        );
                    }
                    emit DividendWithdrawn(
                        account,
                        destination,
                        dividendToken.token,
                        tokens
                    );
                }
            }
        }
    }

    /// @notice Withdraw enabled dividends tokens
    function withdrawDividends() public {
        _withdrawDividendsFor(msg.sender, msg.sender);
    }

    /// @notice Withdraw enabled and disabled dividends tokens
    function withdrawDividendByToken(address token) public {
        _updateAccount(msg.sender);
        uint256 tokens = accounts[msg.sender].owing[token];
        if (tokens > 0) {
            accounts[msg.sender].owing[token] = 0;
            if (token == address(0)) {
                require(payable(msg.sender).send(tokens), "ETH send failure");
            } else {
                require(
                    ERC20(token).transfer(msg.sender, tokens),
                    "ERC20 transfer failure"
                );
            }
        }
        emit DividendWithdrawn(msg.sender, msg.sender, token, tokens);
    }

    /// @notice Mint tokens
    function mint(address tokenOwner, uint256 tokens)
        external
        override
        permitted(Roles.MintTokens, tokens)
        returns (bool success)
    {
        _updateAccount(tokenOwner);
        accounts[tokenOwner].balance += tokens;
        _totalSupply += tokens;
        emit Transfer(address(0), tokenOwner, tokens);
        return true;
    }

    /// @notice Burn tokens
    function burn(uint256 tokens) external override returns (bool success) {
        _updateAccount(msg.sender);
        _withdrawDividendsFor(msg.sender, msg.sender);
        accounts[msg.sender].balance -= tokens;
        _totalSupply -= tokens;
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }

    /// @notice Withdraw enabled dividends tokens before burning
    function burnFrom(address tokenOwner, uint256 tokens)
        external
        override
        permitted(Roles.BurnTokens, tokens)
        returns (bool success)
    {
        require(accounts[tokenOwner].balance >= tokens, "Insufficient tokens");
        _withdrawDividendsFor(tokenOwner, tokenOwner);
        accounts[tokenOwner].balance -= tokens;
        _totalSupply -= tokens;
        emit Transfer(tokenOwner, address(0), tokens);
        return true;
    }

    /// @notice Recover tokens for non enabled dividend tokens
    function recoverTokens(address token, uint256 tokens)
        public
        permitted(Roles.RecoverTokens, 0)
    {
        TokenList.Token memory dividendToken = dividendTokens.entries[token];
        require(
            dividendToken.timestamp == 0 || !dividendToken.enabled,
            "Cannot recover tokens for enabled dividend token"
        );
        if (token == address(0)) {
            require(
                payable(msg.sender).send(
                    (tokens == 0 ? address(this).balance : tokens)
                ),
                "ETH send failure"
            );
        } else {
            require(
                ERC20(token).transfer(
                    msg.sender,
                    tokens == 0 ? ERC20(token).balanceOf(address(this)) : tokens
                ),
                "ERC20 transfer failure"
            );
        }
    }
}
