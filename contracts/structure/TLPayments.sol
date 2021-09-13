pragma solidity ^0.5.0;

import "./Util.sol";
import "./TLType.sol";
import "./TLStorage.sol";
import "./TiesDBAPI.sol";

library TLPayments {

    using TLPayments for TLType.Payments;
    using TLStorage for TLType.Storage;

    function getOperationRedeemed(TLType.Payments storage p, bytes32 tKey, address account, bytes16 session) external view returns (uint crops, uint tokens, uint nonce) {
        TLType.Payment storage op = p.ap[tKey].ps[account].ops[session];
        crops = op.crops;
        tokens = op.paidTokens;
        nonce = op.nonce;
    }

    function addPriceForIndex(TLType.Payments storage p, bytes32 tKey, uint8 iType) public {
        TLType.PaymentAccount storage pa = p.ap[tKey];
        pa.ocppn += getPriceForIndexType(iType);
    }

    function removePriceForIndex(TLType.Payments storage p, bytes32 tKey, uint8 iType) public {
        TLType.PaymentAccount storage pa = p.ap[tKey];
        pa.ocppn -= getPriceForIndexType(iType);
    }

    function getPriceForIndexType(uint8 iType) internal pure returns (uint price) {
        if((uint8(1) & iType) > 0) {
            price += 100;
        }
        if((uint8(2) & iType) > 0) {
            price += 1000;
        }
        if((uint8(4) & iType) > 0) {
            price += 5000;
        }
    }

    function redeemOperation(TLType.Payments storage p, TLType.Storage storage s, TiesDBPayment registry, bytes32 tKey, address account, bytes16 session,
        uint crops, uint nonce, bytes memory signature) public {
        require(account == recoverSigner(abi.encodePacked(registry, account, session, tKey, crops, nonce), signature), "Wrong signature");
        TLType.PaymentAccount storage pa = p.ap[tKey];
        TLType.Payment storage op = pa.ps[account].ops[session];
        uint tokensToPayPerNode = updatePayment(op, crops, nonce) * pa.ocppn;
        TLType.Table storage t = s.getTable(tKey);
        op.paidTokens += tokensToPayPerNode * t.nid.length;
        for (uint i = 0; i < t.nid.length; i++) {
            require(registry.payFrom(account, s.nmis[t.nid[i]-1], tokensToPayPerNode), "Token transfer failure paying from user to nodes");
        }
    }

    // function extendStorageTime(...) public {
    //     TODO: Save storage cheque for later redeeming
    // }

    // function redeemStorage(...) public {
    //     TODO: Redeem saved cheques for storage time
    // }

    function updatePayment(TLType.Payment storage p, uint crops, uint nonce) internal returns (uint cropsPayment){
        require(p.crops < crops, "Lesser or equal crops value could not be redeemed");
        require(p.nonce < nonce, "Lesser or equal nonce value could not be redeemed");
        cropsPayment = crops - p.crops;
        p.crops = crops;
        p.nonce = nonce;
    }

    function recoverSigner(bytes memory pack, bytes memory sig) internal pure returns (address) {
        return TiesLibSignature.recoverSigner(TiesLibSignature.prefixed(keccak256(pack)), sig);
    }
}