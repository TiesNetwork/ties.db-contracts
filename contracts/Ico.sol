pragma solidity ^0.4.0;


import "./TieToken.sol";
import "zeppelin/contracts/ownership/Ownable.sol";


contract Ico is Ownable {
    TieToken public token;
    address authority; //An account to purchase tokens for altcoins
    bool public isOpen = false;

    using SafeMath for uint;

    uint private constant decimals = 18;
    uint private constant zeroes = (10**decimals);
    uint private constant CAP = 200*(10**6)*zeroes;
    uint private constant ICO_CAP = 140*1000*1000*zeroes;
    uint private constant BONUS_STEP = 14*1000*1000*zeroes;
    uint private constant PRICE = 0.0025 ether;

    event Error(string msg, uint puint);

    function Ico(address _token, address _multisig, address _authority){
        token = TieToken(_token);
        authority = _authority;
        transferOwnership(_multisig);
    }

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
            uint gapCost = gap*(PRICE*100)/zeroes/bonus;
            if(gapCost >= etherVal){
                //If the gap is large enough just sell the necessary amount of tokens
                tokens += etherVal.mul(bonus).mul(zeroes)/(PRICE*100);
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
        uint tokens = getTokensAmount(amount);

        require(tokens.add(token.totalSupply()) <= ICO_CAP);

        owner.transfer(amount);
        token.mint(to, tokens);
    }

    modifier onlyAuthority() {
        require(msg.sender == authority);
        _;
    }

    modifier onlyOpen() {
        require(isOpen);
        _;
    }

    function open(bool open) onlyOwner {
        isOpen = open;
    }

    /**
    * Used to buy tokens for altcoins
    */
    function buyAlt(address to, uint etherAmount) onlyOpen onlyAuthority {
        uint tokens = getTokensAmount(etherAmount);

        require(tokens.add(token.totalSupply()) <= ICO_CAP);

        token.mint(to, tokens);
    }

    function () payable{
        buy(msg.sender);
    }

    function finalize() onlyOwner {
        uint diff = CAP.sub(token.totalSupply());
        if(diff > 0) //The unsold capacity moves to team
            token.mint(owner, diff);
        selfdestruct(owner);
    }
}
