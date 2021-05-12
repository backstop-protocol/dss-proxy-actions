/// BProxyActions.sol

pragma solidity ^0.5.12;

import "./DssProxyActions.sol";

contract BManagerLike is ManagerLike {
    function cushion(uint cdp) public returns(uint);
}

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

    function lockGemViaCdp(
        address manager,
        address gemJoin,
        uint cdp,
        uint amt,
        bool transferFrom
    ) public {
        address urn = ManagerLike(manager).urns(cdp);

        // Receives Gem and joins it into the vat        
        gemJoin_join(gemJoin, urn, amt, transferFrom);

        // Locks WETH amount into the CDP and generates debt
        frob(manager, cdp, toInt(convertTo18(gemJoin, amt)), 0);
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

    function openLockGemAndGiveToProxy(
        address proxyRegistry,
        address manager,
        address gemJoin,
        bytes32 ilk,
        address dst,
        uint    amt,
        bool    transferFrom
    ) public returns (uint cdp) {
        cdp = open(manager, ilk, address(this));
        lockGemViaCdp(manager,gemJoin,cdp,amt,transferFrom);
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

    function beforeWipeAll(address manager, uint cdp) internal {
        if(BManagerLike(manager).cushion(cdp) > 0) ManagerLike(manager).frob(cdp,0,0);
    }

    function wipeAll(
        address manager,
        address daiJoin,
        uint cdp
    ) public {
        beforeWipeAll(manager, cdp);
        super.wipeAll(manager, daiJoin, cdp);
    }

    function safeWipeAll(
        address manager,
        address daiJoin,
        uint cdp,
        address owner
    ) public {
        beforeWipeAll(manager, cdp);
        super.safeWipeAll(manager, daiJoin, cdp, owner);
    }

    function wipeAllAndFreeETH(
        address manager,
        address ethJoin,
        address daiJoin,
        uint cdp,
        uint wadC
    ) public {
        beforeWipeAll(manager, cdp);
        super.wipeAllAndFreeETH(manager, ethJoin, daiJoin, cdp, wadC);
    }

    function wipeAllAndFreeGem(
        address manager,
        address gemJoin,
        address daiJoin,
        uint cdp,
        uint amtC
    ) public {
        beforeWipeAll(manager, cdp);
        super.wipeAllAndFreeGem(manager, gemJoin, daiJoin, cdp, amtC);
    }
}
