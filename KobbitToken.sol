pragma solidity ^0.4.15;

/*
Owner contract that determines the owner. Includes a transfer function of ownership.
*/
contract Owned {
    address public owner; // The owner address.

    event OwnerUpdate(address newOwner); // Event listener for owner update.

    /*
    @dev constructor is activated when the contract is deployed.
    */
    function Owned() public {
        owner = msg.sender; // Set the msg.sender to owner.
    }

    /*
    @dev checks if the owner is the msg.sender.
    */
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /*
    @dev transfer the ownership to a new owner.

    @param _newOwner the address of the new owner.
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(owner != _newOwner); // Checks if the owner equals _newOwner.
        owner = _newOwner; // Set the owner to new owner.
        emit OwnerUpdate(owner); // Send to event listener.
    }
}

/*
Provides utilities and support for other contracts like controlling calculation.
*/
contract Utils {

    /**
        @dev constructor.
    */
    function Utils() public {
    }

    /**
    @dev checks the validity of the address.

    @param _address the address being checked.
    @return success if calculations are correct.
    */
    function check(address _address) public pure returns (bool success) {
        assert(_address != 0x0);
        return true;
    }

    /**
    @dev checks the addition math between two variables.

    @param _x first variable.
    @param _y second variable.
    @return z if calculations are correct.
    */
    function add(uint256 _x, uint256 _y) public pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
    @dev checks the subtraction math between two variables.

    @param _x first variable.
    @param _y second variable.
    @return z if calculations are correct.
    */
    function sub(uint256 _x, uint256 _y) public pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
    @dev checks the multiplication math between two variables.

    @param _x first variable.
    @param _y second variable.
    @return z if calculations are correct.
    */
    function mul(uint256 _x, uint256 _y) public pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }

    /**
    @dev checks the division math between two variables.

    @param _x first variable.
    @param _y second variable.
    @return z if calculations are correct.
    */
    function div(uint256 _x, uint256 _y) public pure returns (uint256) {
        uint256 z = _x / _y;
        return z;
    }
}

/*
Basic token functions based on ERC20Token. Base for KobbitToken.
*/
contract Token is Utils{
    string public name; // The name of the token.
    string public symbol; // The symbol of the token.
    uint8 public decimals; // Amount of decimals in token number.
    uint256 public totalSupply; // The total supply of the token.

    mapping (address => uint256) public balanceOf; // Checks the balance of an address.
    mapping (address => mapping (address => uint256)) public allowance; // Checks the allowance that another sender have.

    event Transfer(address indexed from, address indexed to, uint256 value); // Transfer broadcast message.
    event Approval(address indexed owner, address indexed _spender, uint256 _value); // Approval broadcast message.

    /*
    @dev the constructor that initiate initialSupply, tokenName, decimalUnits, tokenSymbol. Sets variable values.

    @param initialSupply the starting supply amount.
    @param tokenName the name of the token.
    @param decimalUnits decimals unit for token supply.
    @param tokenSymbol the symbol for the token.
    */
    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
        balanceOf[msg.sender] = initialSupply; // Give the owner all of the token supply.
        totalSupply = initialSupply; // The initialSupply equals totalSupply.
        name = tokenName; // Give the token a name.
        symbol = tokenSymbol; // Symbol of the token.
        decimals = decimalUnits; // Given decimal units.
    }

    /*
    @dev transfer token from msg.sender to an address.

    @param _to the address that token will be sent to.
    @param _value token value sent.
    @return true if successful.
    */
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        check(_to); // Checks if the address is valid.
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], _value); // Substract from msg.sender.
        balanceOf[_to] += add(balanceOf[_to], _value); // Add to address given in param.
        emit Transfer(msg.sender, _to, _value); // Send broadcast message.
        return true;
    }

    /*
    @dev approves a address to spend on your behalf.

    @param _spender address of the spender.
    @param _value allowance token amount.
    @return true if successful.
    */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        check(_spender); // Checks if _spender is a valid address.
        allowance[msg.sender][_spender] = _value; // Give allowance to _spender.
        emit Approval(msg.sender, _spender, _value); // Broadcast a message about the approval.
        return true;
    }

    /*
    @dev transfer token from an address to an address.

    @param _from the token address being sent from.
    @param _to the token address being sent to.
    @param _value token value being sent.
    @return returns true if successful.
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        check(_from); // Checks validity of address _from.
        check(_to); // Checks validity of address _to.
        allowance[_from][msg.sender] = sub(allowance[_from][msg.sender], _value); // Substract from allowance.
        balanceOf[_from] = sub(balanceOf[_from], _value); // Substract from address _from.
        balanceOf[_to] = add(balanceOf[_to], _value); // Add to address _to.
        emit Transfer(_from, _to, _value); // Broadcast transfer listenener.
        return true;
    }
}

/*
The smart token contract that has addition functions on-top of Token contract.
Functionalities, that handles the smart token, are implemented in this contract.
*/
contract Kobbit is Owned, Token {
    uint public stakeRateInterest; // The interest rate of staking.
    uint public tokenPriceInWei; // The price per token.
    uint public stakeIntervalInMinutes; // The time interval between stakes.
    mapping (address => uint) public timeUntilNextStake; // The time until next available stake.

    event Staked(address stakingAddress, uint stakeAmount); // Broadcast if token is being staked.
    event TokenBought(address buyer, uint tokenAmount, uint etherAmount); // Broadcast if token is being bought.
    event TokenSold(address seller, uint tokenAmount); // Broadcast if token is being sold.
    event PaymentConfirmed(address from, uint tokenAmount); // Broadcast if payment is confirmed.

    /*
    @dev checks if the address is allowed to stake.

    @param check the address being checked.
    */
    modifier allowStake(address check) {
        assert(now >= timeUntilNextStake[check]);
        _;
    }

    /*
    @dev constructor that uses the basic token address to set variables.
    Setup the kobbit contract first time.

    @param initialSupply the initial supply of token.
    @param tokenName name of the token.
    @param decimalUnits assign decimal units for token.
    @param tokenSymbol assign the token symbol.
    @param interestRateInPercentage the interest rate of staking.
    @param etherCostOfEachToken the cost of token per ether.
    @param minutesBetweenStaking the time interval between stake.
    */
    function Kobbit(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        uint interestRateInPercentage,
        uint etherCostOfEachToken,
        uint minutesBetweenStaking
    ) public Token (initialSupply, tokenName, decimalUnits, tokenSymbol) {
        stakeRateInterest = interestRateInPercentage; // Set stakeRateInterest.
        tokenPriceInWei = etherCostOfEachToken * 1 ether; // Set the price of token per ether.
        stakeIntervalInMinutes = minutesBetweenStaking; // Set the time interval between stakes.
    }

    /*
    @dev staking function that stakes to an address.

    @param _to address being staked.
    @return true if successful.
    */
    function stake(address _to)
        public
        allowStake(_to)
        ownerOnly
        returns (bool success)
    {
        uint temp = mul(balanceOf[_to], stakeRateInterest); // Multiplies the balanceOf address with stakeRateInterest.
        uint stakeValue = div(temp, 100); // Divide the temporary value with 100, and we get stakeValue. Float numbers doesn't exist in EVM.
        balanceOf[_to] = add(balanceOf[_to], stakeValue); // Add the stakeValue to balanceOf address.
        totalSupply = add(totalSupply, stakeValue); // Add tokens to totalSupply.
        timeUntilNextStake[_to] = now + stakeIntervalInMinutes * 1 minutes; // Set the timer for next staking possibility.

        emit Staked(_to, stakeValue); // Broadcast a message.
        return true;
    }

    /*
    @dev buy function that can be executed by owner or contract.

    @param from the address buying the token.
    @param amount amount of token being bought.
    @param return true if successful.
    */
    function buy(address from, uint amount)
        public
        ownerOnly
        returns (bool success)
    {
        balanceOf[from] = add(balanceOf[from], amount); // Add the amount to given address.
        balanceOf[msg.sender] = sub(balanceOf[msg.sender], amount); // Substract from the msg.sender.

        emit TokenBought(from, amount, amount / 1 ether); // Broadcast how many tokens were bought.
        return true;
    }

    /*
    @dev sell function that can be executed by owner or contract.

    @param from the address selling the token.
    @param amount amount of token being sold
    @param return true if successful.
    */
    function sell(uint256 amount, address from)
        public
        ownerOnly
        returns (bool success)
    {
        balanceOf[msg.sender] = add(balanceOf[msg.sender], amount); // Add the amount to msg.sender.
        balanceOf[from] = sub(balanceOf[from], amount); // Substract from the address from.

        emit TokenSold(from, amount); // Broadcast the amount of token sold.
        return true;
    }

    /*
    @dev pay function that transfers token.

    @param _from the address that's paying.
    @param _amount amount being paid.
    @return true if successful.
    */
    function pay(address _from, uint256 _amount)
        public
        ownerOnly
        returns (bool success)
    {
        balanceOf[_from] = sub(balanceOf[_from], _amount); // Substract from the payer.
        balanceOf[msg.sender] = add(balanceOf[msg.sender], _amount); // Add to the msg.sender.

        emit PaymentConfirmed(_from, _amount); // Broadcast a message, payment confirmed.
        return true;
    }

    // Kill of the contract and return ether to owner.
    function kill() public { if (msg.sender == owner) selfdestruct(owner); }
}
