/// BProxyActions.sol

pragma solidity ^0.5.12;

import "./DssProxyActions.sol";

contract BProxyActions is DssProxyActions {
    function shiftManager(
        address managerSrc,
        address managerDst,
        uint cdpSrc,
        uint cdpDst
    ) public {
        address vat = ManagerLike(managerSrc).vat();
        require(vat == ManagerLike(managerDst).vat(), "vat-mismatch");

        bool canSrc = (VatLike(vat).can(address(this), managerSrc) != 0);
        bool canDst = (VatLike(vat).can(address(this), managerDst) != 0);

        if(! canSrc) hope(vat, managerSrc);
        if(! canDst) hope(vat, managerDst);

        quit(managerSrc, cdpSrc, address(this));
        enter(managerDst, address(this), cdpDst);

        if(! canSrc) nope(vat, managerSrc);
        if(! canDst) nope(vat, managerDst);
    }

    function lockETHViaCdp(
        address manager,
        address ethJoin,
        uint cdp
    ) public payable {
        address urn = ManagerLike(manager).urns(cdp);

        // Receives ETH amount, converts it to WETH and joins it into the vat
        ethJoin_join(ethJoin, urn);
        // Locks WETH amount into the CDP and generates debt
        frob(manager, cdp, toInt(msg.value), 0);
    }

    function openLockETHAndGiveToProxy(
        address proxyRegistry,
        address manager,
        address ethJoin,
        bytes32 ilk,
        address dst
    ) public payable returns (uint cdp) {
        cdp = open(manager, ilk, address(this));
        lockETHViaCdp(manager,ethJoin,cdp);
        giveToProxy(proxyRegistry,manager,cdp,dst);
    }

    function openAndImportFromManager(
        address managerSrc,
        address managerDst,
        uint cdpSrc,
        bytes32 ilk
    ) public payable returns (uint cdp) {
        cdp = open(managerDst, ilk, address(this));
        shiftManager(managerSrc,managerDst,cdpSrc,cdp);
    }
}
