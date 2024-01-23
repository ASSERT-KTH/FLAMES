// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/ISolidlyV3PoolImmutables.sol';
import './pool/ISolidlyV3PoolState.sol';
import './pool/ISolidlyV3PoolQuoter.sol';
import './pool/ISolidlyV3PoolActions.sol';
import './pool/ISolidlyV3PoolOwnerActions.sol';
import './pool/ISolidlyV3PoolEvents.sol';

/// @title The interface for a Solidly V3 Pool
/// @notice A Solidly pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface ISolidlyV3Pool is
    ISolidlyV3PoolImmutables,
    ISolidlyV3PoolState,
    ISolidlyV3PoolQuoter,
    ISolidlyV3PoolActions,
    ISolidlyV3PoolOwnerActions,
    ISolidlyV3PoolEvents
{

}
