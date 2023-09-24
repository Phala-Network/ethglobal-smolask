// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import 'test/base/BaseTest.t.sol';
import {IntentAction} from 'contracts/modules/act/intent/IntentAction.sol';
import {Events} from 'contracts/libraries/constants/Events.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
    constructor(string memory currency, string memory symbol) ERC20(currency, symbol) {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract CollectPublicationActionTest is BaseTest {
    using stdJson for string;
    using Strings for uint256;

    IntentAction intentAction;
    MockERC20 token0;
    MockERC20 token1;

    TestAccount seller;
    TestAccount buyer;

    address collectNFTImpl;
    address mockCollectModule;

    // event CollectModuleWhitelisted(address collectModule, bool whitelist, uint256 timestamp);
    // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public override {
        super.setUp();

        // Deploy & Whitelist MockCollectModule
        // mockCollectModule = address(new MockCollectModule());
        // vm.prank(moduleGlobals.getGovernance());
        // collectPublicationAction.whitelistCollectModule(mockCollectModule, true);

        seller = _loadAccountAs('SELLER');
        buyer = _loadAccountAs('BUYER');
        token0.mint(seller.owner, 1000 ether);
        token1.mint(buyer.owner, 1000 ether);
    }

    // Deploy CollectPublicationAction
    constructor() TestSetup() {
        if (fork && keyExists(string(abi.encodePacked('.', forkEnv, '.IntentAction')))) {
            intentAction = IntentAction(
                json.readAddress(string(abi.encodePacked('.', forkEnv, '.IntentAction')))
            );
            console.log('Found intentAction deployed at:', address(intentAction));
        }

        uint256 deployerNonce = vm.getNonce(deployer);

        // address predictedCollectPublicationAction = computeCreateAddress(deployer, deployerNonce);
        // address predictedCollectNFTImpl = computeCreateAddress(deployer, deployerNonce + 1);

        vm.startPrank(deployer);
        intentAction = new IntentAction(address(hub));
        token0 = new MockERC20('USDC', 'USDC');
        token1 = new MockERC20('Phala Token', 'PHA');
        vm.stopPrank();

        // assertEq(
        //     address(collectPublicationAction),
        //     predictedCollectPublicationAction,
        //     'CollectPublicationAction deployed address mismatch'
        // );
        // assertEq(collectNFTImpl, predictedCollectNFTImpl, 'CollectNFTImpl deployed address mismatch');

        vm.label(address(intentAction), 'IntentAction');
        vm.label(address(token0), 'Token0');
        vm.label(address(token1), 'Token1');
    }

    function testProcessPublicationAction_firstCollect(
        // uint256 profileId,
        uint256 pubId,
        // uint256 actorProfileId,
        // address actorProfileOwner,
        address transactionExecutor
    ) public {
        // vm.assume(profileId != 0);
        vm.assume(pubId != 0);
        // vm.assume(actorProfileId != 0);
        // vm.assume(actorProfileOwner != address(0));
        vm.assume(transactionExecutor != address(0));
        // vm.assume(collectPublicationAction.getCollectData(profileId, pubId).collectModule == address(0));

        // sell 100 Token0
        // buy 1000 Token1

        vm.prank(seller.owner);
        token0.approve(address(intentAction), 1000 ether);
        bytes memory initData = abi.encode(IntentAction.IntentInitParams({
            tokenToSell: address(token0),
            amountToSell: 100 ether,
            tokenToBuy: address(token1),
            blockTsTtl: block.timestamp + 60
        }));
        vm.prank(address(hub));
        intentAction.initializePublicationAction(seller.profileId, pubId, transactionExecutor, initData);

        assertEq(token0.balanceOf(seller.owner), 900 ether, 'token0 secured');

        vm.prank(buyer.owner);
        token1.approve(address(intentAction), 1000 ether);
        bytes memory actData = abi.encode(IntentAction.FillAction({
            amountToOffer: 1000 ether
        }));

        Types.ProcessActionParams memory processActionParams = Types.ProcessActionParams({
            publicationActedProfileId: seller.profileId,
            publicationActedId: pubId,
            actorProfileId: buyer.profileId,
            actorProfileOwner: buyer.owner,
            transactionExecutor: transactionExecutor,
            referrerProfileIds: _emptyUint256Array(),
            referrerPubIds: _emptyUint256Array(),
            referrerPubTypes: _emptyPubTypesArray(),
            actionModuleData: actData
        });

        // vm.expectEmit(true, true, true, true, address(collectNFT));
        // emit Transfer({from: address(0), to: actorProfileOwner, tokenId: 1});

        // vm.expectEmit(true, true, true, true, address(collectPublicationAction));
        // emit Events.Collected({
        //     collectActionParams: processActionParams,
        //     collectModule: mockCollectModule,
        //     collectNFT: collectNFT,
        //     tokenId: 1,
        //     collectActionResult: abi.encode(true),
        //     timestamp: block.timestamp
        // });

        // vm.expectCall(collectNFT, abi.encodeCall(CollectNFT.initialize, (profileId, pubId)), 1);

        skip(60);  // after the deadline
        vm.prank(address(hub));
        bytes memory _returnData = intentAction.processPublicationAction(processActionParams);

        assertEq(token1.balanceOf(seller.owner), 1000 ether, "incorrect token1 seller received");
        assertEq(token0.balanceOf(buyer.owner), 100 ether, "incorrect token0 buyer received");
    }

}
