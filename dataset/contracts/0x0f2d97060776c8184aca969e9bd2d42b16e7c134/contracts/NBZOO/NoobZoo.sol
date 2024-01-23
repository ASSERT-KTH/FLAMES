// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './NoobZooBase.sol';
import './NoobZooSplitsAndRoyalties.sol';

/**
 * @title NoobZoo Wrapper Contract
 *              __    
 *      __     /  \     __ 
 *     /  \    \__/    /  \
 *     \__/ __________ \__/
 *   _   _ / ___   ___\  ____ __________   ____
 *  | \ | |/ __ \ / __ \|  _ \___  / __ \ / __ \
 *  |  \| | | *| | | *| | |_) | / / |  | | |  | |
 *  | . ` | |__| | |__| |  _ < / /| |  | | |  | |
 *  | |\  |      |      | |_) / /_| |__| | |__| |
 *  |_| \_|\____/ \____/|____/_____\____/ \____/
 *         \__________/
 */
contract NoobZoo is NoobZooSplitsAndRoyalties, NoobZooBase {
    constructor()
        NoobZooBase(
            'NoobZoo',
            'NBZOO',
            'ipfs://QmZu6EBNoVzzSugDWJeKkP9FMFsK9hQ3pXJZd89ay1eQnb/',
            addresses,
            splits,
            0 ether,
            0 ether,
            0 ether
        )
    {
        // Implementation version: v1.0.0
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}
