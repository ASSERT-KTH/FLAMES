// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.8.17;

error WrongStateException(
    StatefulContract.State expected,
    StatefulContract.State current
);
error UpgradeStateException(
    StatefulContract.State currentState,
    StatefulContract.State newState
);

abstract contract StatefulContract {
    event UpgradedState(State oldState, State newState);

    // Explanation of the different contract states
    //
    // UNINITIALIZED: The contract was created, but setup() was not called
    // PROTECTED: The contract is now set up, allowing the owner to add liquidity and renounce ownership
    //            Snipers will be automatically blocked if they try to buy during the PROTECTED state
    // THROTTLED: Trading is open but buys limits are enforced, and smart contracts cannot buy to ensure a fair launch
    // OPEN: All trading restrictions are lifted
    //
    enum State {
        UNINITIALIZED,
        PROTECTED,
        THROTTLED,
        OPEN
    }

    State private currentState = State.UNINITIALIZED;

    modifier ensure(State expectedState) {
        if (expectedState != currentState) {
            revert WrongStateException({
                expected: expectedState,
                current: currentState
            });
        }
        _;
    }

    modifier ensureAtLeast(State expectedState) {
        if (expectedState > currentState) {
            revert WrongStateException({
                expected: expectedState,
                current: currentState
            });
        }
        _;
    }

    function _getState() internal view returns (State) {
        return currentState;
    }

    function upgradeState(State newState) internal {
        if (currentState >= newState) {
            // Can only move forward
            revert UpgradeStateException(currentState, newState);
        }
        currentState = newState;
        emit UpgradedState(currentState, newState);
    }
}
