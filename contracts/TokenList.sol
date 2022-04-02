pragma solidity ^0.8.0;

/// @notice TokenList to map [token] => [enabled]
// SPDX-License-Identifier: GPLv2
library TokenList {
    struct Token {
        uint256 timestamp;
        uint256 index;
        address token;
        bool enabled;
    }
    struct Data {
        bool initialised;
        mapping(address => Token) entries;
        address[] index;
    }

    event TokenAdded(address indexed token, bool enabled);
    event TokenRemoved(address indexed token);
    event TokenUpdated(address indexed token, bool enabled);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }

    function add(
        Data storage self,
        address token,
        bool enabled
    ) internal {
        require(self.entries[token].timestamp == 0, "Cannot add duplicate");
        self.index.push(token);
        self.entries[token] = Token(
            block.timestamp,
            self.index.length - 1,
            token,
            enabled
        );
        emit TokenAdded(token, enabled);
    }

    function remove(Data storage self, address token) internal {
        require(self.entries[token].timestamp > 0, "Not registered");
        uint256 removeIndex = self.entries[token].index;
        emit TokenRemoved(token);
        uint256 lastIndex = self.index.length - 1;
        address lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[token];
        if (self.index.length > 0) {
            self.index.pop();
        }
    }

    function update(
        Data storage self,
        address token,
        bool enabled
    ) internal {
        Token storage entry = self.entries[token];
        require(entry.timestamp > 0, "Not registered");
        entry.timestamp = block.timestamp;
        entry.enabled = enabled;
        emit TokenUpdated(token, enabled);
    }

    function length(Data storage self) internal view returns (uint256) {
        return self.index.length;
    }
}
