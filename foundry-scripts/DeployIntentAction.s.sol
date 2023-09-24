pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import 'forge-std/console2.sol';

import 'contracts/mock/IntentAction.sol';

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

        address[] memory users = new address[3];
        users[0] = vm.addr(vm.deriveKey(deployerMnemonic, 0));
        users[1] = vm.addr(vm.deriveKey(deployerMnemonic, 1));
        users[2] = vm.addr(vm.deriveKey(deployerMnemonic, 2));

        // Start deployments.
        vm.startBroadcast(deployerKey);
        IntentAction action = new IntentAction(users);
        console.log("IntentAction Address:", address(action));
        vm.stopBroadcast();
    }
}
