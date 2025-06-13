// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
// import {CampusCredit} from "../src/CampussCredit.sol";

import {CourseBadge} from "../src/CourseBadge.sol";

// import {StudentID} from "../src/StudentID.sol";

contract Deployer is Script {
    function run() public {
        vm.startBroadcast();

        // CampusCredit t1 = new CampusCredit();
        // console.log("CampusCredit deployed at:", address(t1));

        CourseBadge t2 = new CourseBadge();
        console.log("CourseBadge deployed at:", address(t2));

        // StudentID t3 = new StudentID();
        // console.log("StudentID deployed at:", address(t3));

        vm.stopBroadcast();
    }
}
