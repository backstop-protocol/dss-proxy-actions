pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./DssProxyActions.sol";

contract DssProxyActionsTest is DSTest {
    DssProxyActions actions;

    function setUp() public {
        actions = new DssProxyActions();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
