// contracts/VibeDeposit.sol
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @author nemusona
/// @title Mock ERC20 for testing
contract MockERC20 is ERC20("Mock", "MOCK") {

    function mint(address _to, uint _amount) public {
        _mint(_to, _amount);
    }

}