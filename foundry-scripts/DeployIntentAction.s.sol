pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import 'forge-std/console2.sol';

import 'contracts/LensHub.sol';
import 'contracts/FollowNFT.sol';
import 'contracts/modules/act/collect/CollectNFT.sol';

import {IntentAction} from 'contracts/modules/act/intent/IntentAction.sol';

/**
 * This script will deploy the current repository implementations, using the given environment
 * hub proxy address.
 */
contract DeployUpgradeScript is Script {
    function run() public {
        string memory deployerMnemonic = vm.envString('MNEMONIC');
        uint256 deployerKey = vm.deriveKey(deployerMnemonic, 0);
        address deployer = vm.addr(deployerKey);
        address hubProxyAddr = 0xC1E77eE73403B8a7478884915aA599932A677870;

        address owner = deployer;

        LensHub hub = LensHub(hubProxyAddr);


        // uint256 deployerNonce = vm.getNonce(deployer);

        // // Precompute needed addresss.
        // address lensHandlesAddress = computeCreateAddress(deployer, deployerNonce);
        // address migratorAddress = computeCreateAddress(deployer, deployerNonce + 1);
        // address tokenHandleRegistryAddress = computeCreateAddress(deployer, deployerNonce + 2);

        // Start deployments.
        vm.startBroadcast(deployerKey);
        // uint256 profileId0 = hub.createProfile(Types.CreateProfileParams({
        //     to: deployer,
        //     imageURI: "",
        //     followModule: address(0),
        //     followModuleInitData: bytes("")
        // }));
        // uint256 profileId1 = hub.createProfile(Types.CreateProfileParams({
        //     to: deployer,
        //     imageURI: "",
        //     followModule: address(0),
        //     followModuleInitData: bytes("")
        // }));

        IntentAction intentAction = new IntentAction(address(hub));
        console.log("IntentAction Address:", address(intentAction));

        vm.stopBroadcast();
    }
}
