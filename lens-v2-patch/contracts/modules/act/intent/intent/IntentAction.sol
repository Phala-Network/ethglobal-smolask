// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IPublicationActionModule} from 'contracts/interfaces/IPublicationActionModule.sol';
import {ICollectModule} from 'contracts/interfaces/ICollectModule.sol';
import {ICollectNFT} from 'contracts/interfaces/ICollectNFT.sol';
import {Types} from 'contracts/libraries/constants/Types.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
// import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';
import {Errors} from 'contracts/libraries/constants/Errors.sol';
import {HubRestricted} from 'contracts/base/HubRestricted.sol';
import {IModuleGlobals} from 'contracts/interfaces/IModuleGlobals.sol';

import {ILensHub} from 'contracts/interfaces/ILensHub.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract IntentAction is HubRestricted, IPublicationActionModule {
    using SafeERC20 for IERC20;

    // uint256 constant FILL = 0;

    error BadInitParam();
    error blockTsTtlTooEarly();
    error TooEarlyToFill();
    error IntentAlreadyCancelled(uint256 profileId, uint256 pubId);

    struct IntentInitParams {
        address tokenToSell;
        uint256 amountToSell;
        address tokenToBuy;
        uint256 blockTsTtl;
    }

    struct FillAction {
        uint256 amountToOffer;
    }

    struct IntentInfo {
        uint256 sellerProfileId;
        bool activated;
    }

    // address public immutable COLLECT_NFT_IMPL;
    // address public immutable MODULE_GLOBALS;

    // mapping(address collectModule => bool isWhitelisted) internal _collectModuleWhitelisted;
    // mapping(uint256 profileId => mapping(uint256 pubId => CollectData collectData)) internal _collectDataByPub;

    mapping(uint256 profileId => mapping(uint256 pubId => IntentInitParams intentData)) internal _intentDataByPub;
    mapping(uint256 profileId => mapping(uint256 pubId => IntentInfo info)) internal _infoByPub;

    constructor(address hub) HubRestricted(hub) {
        // COLLECT_NFT_IMPL = collectNFTImpl;
        // MODULE_GLOBALS = moduleGlobals;
    }

    function initializePublicationAction(
        uint256 profileId,
        uint256 pubId,
        address /*transactionExecutor*/,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        IntentInitParams memory params = abi.decode(data, (IntentInitParams));
        if (params.tokenToSell == address(0)
            || params.tokenToBuy == address(0)
            || params.amountToSell == 0) {
            revert BadInitParam();
        }
        if (params.blockTsTtl <= block.timestamp) {
            revert blockTsTtlTooEarly();
        }

        // Secure the order
        address owner = ILensHub(HUB).ownerOf(profileId);
        IERC20(params.tokenToSell).transferFrom(owner, address(this), params.amountToSell);

        _intentDataByPub[profileId][pubId] = params;
        _infoByPub[profileId][pubId] = IntentInfo({
            sellerProfileId: profileId,
            activated: true
        });
        return data;
    }

    function processPublicationAction(
        Types.ProcessActionParams calldata processActionParams
    ) external override onlyHub returns (bytes memory) {
        // Basic intent check
        if (!_infoByPub
                [processActionParams.publicationActedProfileId]
                [processActionParams.publicationActedId]
                .activated) {
            revert IntentAlreadyCancelled(
                processActionParams.publicationActedProfileId,
                processActionParams.publicationActedId
            );
        }
        IntentInitParams memory intent = _intentDataByPub
            [processActionParams.publicationActedProfileId]
            [processActionParams.publicationActedId];
        if (block.timestamp < intent.blockTsTtl) {
            revert TooEarlyToFill();
        }
        IntentInfo memory info = _infoByPub
            [processActionParams.publicationActedProfileId]
            [processActionParams.publicationActedId];

        FillAction memory fill = abi.decode(processActionParams.actionModuleData, (FillAction));
        
        address buyer = ILensHub(HUB).ownerOf(processActionParams.actorProfileId);
        address seller = ILensHub(HUB).ownerOf(info.sellerProfileId);
        IERC20(intent.tokenToBuy).transferFrom(buyer, seller, fill.amountToOffer);
        IERC20(intent.tokenToSell).transfer(buyer, intent.amountToSell);

        return bytes(""); //abi.encode(tokenId, collectActionResult);
    }

    // function cancelOrder(
    //     uint256 profileId,
    //     uint256 pubId,
    // ) external {

    // }
}
