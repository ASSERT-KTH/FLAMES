// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IReleases {
    function releaseExists(uint256 __id) external view returns (bool);

    function mint(address __account, uint256 __id, uint256 __amount) external;

    function maxSupply(uint __id) external returns (uint256);
}

contract Claims is Ownable, Pausable {
    error AccountsAndAmountsDoNotMatch();
    error AmountExceedsAvailableClaims();
    error AmountsDoNotMatchMaxSupply();
    error ClaimIsPaused();
    error Forbidden();
    error HasEnded();
    error HasNotStarted();
    error InvalidAddress();
    error InvalidAmount();
    error InvalidStart();
    error ReleaseNotFound();

    event ClaimCreated(uint256 __releaseID, uint256 __start, uint256 __end);
    event ClaimPaused(uint256 __releaseID);
    event ClaimUnpaused(uint256 __releaseID);

    struct Claim {
        bool paused;
        uint256 start;
        uint256 end;
    }

    mapping(uint256 => Claim) private _claims;
    mapping(uint256 => mapping(address => uint256)) private _availableClaims;

    IReleases private _releasesContract;

    constructor(address __releasesContractAddress) {
        if (__releasesContractAddress == address(0)) {
            revert InvalidAddress();
        }

        _releasesContract = IReleases(__releasesContractAddress);
    }

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIERS
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Checks if sender is EOA.
     *
     * Requirements:
     *
     * - Sender must be EOA.
     */
    modifier onlyEOA() {
        if (tx.origin != msg.sender) {
            revert Forbidden();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // OWNER
    ////////////////////////////////////////////////////////////////////////////

    /**
     * @dev Creates a new claim for a release.
     *
     * Requirements:
     *
     * - Release must exist.
     * - Start must be earlier than End.
     * - Length of Accounts and Amounts must match.
     * - Total Amount must match Max Supply of Release.
     */
    function createClaim(
        uint256 __releaseID,
        uint256 __start,
        uint256 __end,
        address[] memory __accounts,
        uint256[] memory __amounts
    ) external onlyOwner {
        if (!_releasesContract.releaseExists(__releaseID)) {
            revert ReleaseNotFound();
        }

        if (__start > __end) {
            revert InvalidStart();
        }

        if (__accounts.length != __amounts.length) {
            revert AccountsAndAmountsDoNotMatch();
        }

        uint256 total = 0;
        for (uint256 i = 0; i < __amounts.length; i++) {
            total += __amounts[i];
        }

        if (_releasesContract.maxSupply(__releaseID) != total) {
            revert AmountsDoNotMatchMaxSupply();
        }

        for (uint256 i = 0; i < __accounts.length; i++) {
            _availableClaims[__releaseID][__accounts[i]] = __amounts[i];
        }

        _claims[__releaseID] = Claim({
            paused: false,
            start: __start,
            end: __end
        });

        emit ClaimCreated(__releaseID, __start, __end);
    }

    /**
     * @dev Pauses contract.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Pauses specific claim.
     */
    function pauseClaim(uint256 __releaseID) external onlyOwner {
        _claims[__releaseID].paused = true;

        emit ClaimPaused(__releaseID);
    }

    /**
     * @dev Unpauses specific claim.
     */
    function unpauseClaim(uint256 __releaseID) external onlyOwner {
        _claims[__releaseID].paused = false;

        emit ClaimUnpaused(__releaseID);
    }

    ////////////////////////////////////////////////////////////////////////////
    // WRITES
    ////////////////////////////////////////////////////////////////////////////

    function useClaim(
        uint256 __releaseID,
        uint __amount
    ) external whenNotPaused onlyEOA {
        if (!_releasesContract.releaseExists(__releaseID)) {
            revert ReleaseNotFound();
        }

        if (__amount == 0) {
            revert InvalidAmount();
        }

        address account = _msgSender();

        if (__amount > availableClaims(account, __releaseID)) {
            revert AmountExceedsAvailableClaims();
        }

        Claim memory claim = _claims[__releaseID];

        if (claim.paused) {
            revert ClaimIsPaused();
        }

        if (block.timestamp < claim.start) {
            revert HasNotStarted();
        }

        if (block.timestamp > claim.end) {
            revert HasEnded();
        }

        _releasesContract.mint(account, __releaseID, __amount);

        _availableClaims[__releaseID][account] -= __amount;
    }

    ////////////////////////////////////////////////////////////////////////////
    // AVAILABLE CLAIMS
    ////////////////////////////////////////////////////////////////////////////

    function availableClaims(
        address __account,
        uint256 __releaseID
    ) public view returns (uint256) {
        return _availableClaims[__releaseID][__account];
    }
}
