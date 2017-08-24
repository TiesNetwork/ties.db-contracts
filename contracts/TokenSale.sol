pragma solidity ^0.4.11;


import "./include/MintableToken.sol";
import "zeppelin/contracts/ownership/Ownable.sol";


contract TokenSale is Ownable {
    using SafeMath for uint;

    // Constants
    // =========

    uint private constant fractions = 1e18;
    uint private constant millions = 1e6*fractions;

    uint private constant CAP = 200*millions;
    uint private constant SALE_CAP = 140*millions;
    uint private constant BONUS_STEP = 14*millions;

    uint private constant PRICE = 0.0025 ether;

    // Events
    // ======

    event AltBuy(address holder, uint tokens, string txHash);
    event Buy(address holder, uint tokens);
    event RunSale();
    event PauseSale();
    event FinishSale();

    // State variables
    // ===============

    MintableToken public token;
    address authority; //An account to control the contract on behalf of the owner
    address robot; //An account to purchase tokens for altcoins
    bool public isOpen = false;

    // Constructor
    // ===========

    function TokenSale(address _token, address _multisig, address _authority, address _robot){
        token = MintableToken(_token);
        authority = _authority;
        robot = _robot;
        transferOwnership(_multisig);
    }

    // Public functions
    // ================

    function getCurrentBonus() constant returns (uint){
        return getBonus(token.totalSupply());
    }

    /**
    * Gets the bonus for the specified total supply
    */
    function getBonus(uint totalSupply) constant returns (uint){
        bytes10 bonuses = "\x14\x11\x0F\x0C\x0A\x08\x06\x04\x02\x00";
        uint level = totalSupply/BONUS_STEP;
        if(level < bonuses.length)
            return uint(bonuses[level]);
        return 0;
    }

    /**
    * Computes number of tokens with bonus for the specified ether. Correctly
    * adds bonuses if the sum is large enough to belong to several bonus intervals
    */
    function getTokensAmount(uint etherVal) constant returns (uint) {
        uint tokens = 0;
        uint totalSupply = token.totalSupply();
        while(true){
            //How much we have before next bonus interval
            uint gap = BONUS_STEP - totalSupply%BONUS_STEP;
            //Bonus at the current interval
            uint bonus = 100 + getBonus(totalSupply);
            //The cost of the entire remainder of this interval
            uint gapCost = gap*(PRICE*100)/fractions/bonus;
            if(gapCost >= etherVal){
                //If the gap is large enough just sell the necessary amount of tokens
                tokens += etherVal.mul(bonus).mul(fractions)/(PRICE*100);
                break;
            }else{
                //If the gap is too small sell it and diminish the price by its cost for the next iteration
                tokens += gap;
                etherVal -= gapCost;
                totalSupply += gap;
            }
        }
        return tokens;
    }

    function buy(address to) onlyOpen payable{
        uint amount = msg.value;
        uint tokens = getTokensAmountUnderCap(amount);

        owner.transfer(amount);
        token.mint(to, tokens);

        Buy(to, tokens);
    }

    function () payable{
        buy(msg.sender);
    }

    // Modifiers
    // =================

    modifier onlyAuthority() {
        require(msg.sender == authority || msg.sender == owner);
        _;
    }

    modifier onlyRobot() {
        require(msg.sender == robot);
        _;
    }

    modifier onlyOpen() {
        require(isOpen);
        _;
    }

    // Priveleged functions
    // ====================

    /**
    * Used to buy tokens for altcoins.
    * Robot may call it before TokenSale officially starts to migrate early investors
    */
    function buyAlt(address to, uint etherAmount, string _txHash) onlyRobot {
        uint tokens = getTokensAmountUnderCap(etherAmount);
        token.mint(to, tokens);
        AltBuy(to, tokens, _txHash);
    }

    function setAuthority(address _authority) onlyOwner {
        authority = _authority;
    }

    function setRobot(address _robot) onlyAuthority {
        authority = _robot;
    }

    // SALE state management: start / pause / finish
    // --------------------------------------------
    function open(bool open) onlyAuthority {
        isOpen = open;
        open ? RunSale() : PauseSale();
    }

    function finalize() onlyAuthority {
        uint diff = CAP.sub(token.totalSupply());
        if(diff > 0) //The unsold capacity moves to team
        token.mint(owner, diff);
        selfdestruct(owner);
        FinishSale();
    }

    // Private functions
    // =========================

    /**
    * Gets tokens for specified ether provided that they are still under the cap
    */
    function getTokensAmountUnderCap(uint etherAmount) private constant returns (uint){
        uint tokens = getTokensAmount(etherAmount);
        require(tokens > 0);
        require(tokens.add(token.totalSupply()) <= SALE_CAP);
        return tokens;
    }

}
