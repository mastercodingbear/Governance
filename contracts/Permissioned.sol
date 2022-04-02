pragma solidity ^0.8.0;

// import "hardhat/console.sol";

/// @notice Permissioned
// SPDX-License-Identifier: GPLv2
contract Permissioned {
    enum Roles {
        SetPermission,
        SetConfig,
        MintTokens,
        BurnTokens,
        RecoverTokens,
        TransferTokens
    }

    struct Permission {
        address account;
        Roles role;
        uint8 active;
        uint256 maximum;
        uint256 processed;
    }

    mapping(bytes32 => Permission) permissions;
    bytes32[] permissionsIndex;

    event PermissionUpdated(
        address indexed account,
        Roles role,
        bool active,
        uint256 maximum,
        uint256 processed
    );

    modifier permitted(Roles role, uint256 tokens) {
        Permission storage permission = permissions[
            keccak256(abi.encodePacked(msg.sender, role))
        ];
        require(
            permission.active == uint8(1) &&
                (permission.maximum == 0 ||
                    permission.processed + tokens <= permission.maximum),
            "Not permissioned"
        );
        permission.processed += tokens;
        _;
    }

    function initPermissioned(address _owner) internal {
        _setPermission(_owner, Roles.SetPermission, true, 0);
    }

    function _setPermission(
        address account,
        Roles role,
        bool active,
        uint256 maximum
    ) internal {
        bytes32 key = keccak256(abi.encodePacked(account, role));
        uint256 processed = permissions[key].processed;
        require(maximum == 0 || maximum >= processed, "Invalid maximum");
        if (permissions[key].account == address(0)) {
            permissions[key] = Permission({
                account: account,
                role: role,
                active: active ? uint8(1) : uint8(0),
                maximum: maximum,
                processed: processed
            });
            permissionsIndex.push(key);
        } else {
            permissions[key].active = active ? uint8(1) : uint8(0);
            permissions[key].maximum = maximum;
        }
        emit PermissionUpdated(account, role, active, maximum, processed);
    }

    function setPermission(
        address account,
        Roles role,
        bool active,
        uint256 maximum
    ) public permitted(Roles.SetPermission, 0) {
        _setPermission(account, role, active, maximum);
    }

    function getPermissionByIndex(uint256 i)
        public
        view
        returns (
            address account,
            Roles role,
            uint8 active,
            uint256 maximum,
            uint256 processed
        )
    {
        require(i < permissionsIndex.length, "Invalid index");
        Permission memory permission = permissions[permissionsIndex[i]];
        return (
            permission.account,
            permission.role,
            permission.active,
            permission.maximum,
            permission.processed
        );
    }

    function permissionsLength() public view returns (uint256) {
        return permissionsIndex.length;
    }
}
