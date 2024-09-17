// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DecentralizedStableCoin} from "../../src/DecntralizedStableCoin.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
     DeployDSC deployer;
     DecentralizedStableCoin dsc;
     DSCEngine engine;
     HelperConfig config;
     address weth;
     address ethUsdPriceFeed;

     function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed,, weth,,) = config.activeNetworkConfig();
     }


     /*//////////////////////////////////////////////////////////////
                            GETUSDVALUETEST
    //////////////////////////////////////////////////////////////*/

     function testGetUsdValue() view public {
      uint256 ethAmount = 15e18;
      uint256 expectedUsdValue = 42000e18;
      uint256 actualUsdValue = engine.getUsdValue(weth, ethAmount);
      assertEq(actualUsdValue, expectedUsdValue);


   }
}