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
Token interface with functions and variable returns.
*/
contract Token {
    //Get the token price in wei.
    function tokenPriceInWei() public constant returns (uint);
    //Transfer to an address from
    function transfer(address _to, uint256 _value) public returns (bool success);
    //Require permission to use this function. Transfer token from a given address.
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    //Approve a certain address to spend on their behalf.
    function approve(address _spender, uint256 _value) public returns (bool success);
    //Stake function based on percentage and time limit.
    function stake(address _to) public returns (bool success);
    //Buy tokens with this function.
    function buy(address from, uint amount) public returns (bool success);
    //Sell tokens and receive ether from the contract.
    function sell(uint256 amount, address from) public returns (bool success);
    //Pay token by transfering from an address to the contract.
    function pay(address _from, uint256 _amount) public returns (bool success);
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
The Organisation that controls functions that the token has.
*/
contract Organisation is Utils, Owned{
    uint public minimumReviews; // Minimum amount of reviews required for approval.
    uint public majorityMarginForContent; // Majority margin for content.
    uint public reviewReward; // Review reward for reviewing a content.
    Token public tokenAddress;  // The token address being used by the organisation.
    uint public contentPrice; // Price for publishing a content.
    uint public reviewPeriodInMinutes;  // Period for a content being open for reviewing.
    mapping (address => Member) public member; // Member information linked to address.
    enum Account {Normal, CEO, Member} // Different type of member privileges.
    Content[] public contents; // Stores the content in a array list.
    uint public numberOfContents; // The total amount of content right now.

    //Event listener that activates when organisation settings are changed.
    event OrganisationSettings(
        Token updatedTokenAddress,
        uint updatedTokenPrice,
        uint updatedMinimumReviews,
        uint updatedMajorityMarginForContent,
        uint updatedReviewReward
    );
    //Event listener that activates when content is added.
    event ContentAdded(uint contentID, string author, string title, string description);
    //Event listener that activates when content is reviewed.
    event Reviewed(uint contentID, bool position, address reviewer, string justification);
    //Event listener that activates when content is executed.
    event ContentTallied(uint contentID, uint result, uint quorum, bool active);

    struct Content {
        address publisherAddress; // The address of the publisher.
        string author; // The author of the content.
        string title; // The title.
        string description; // The description of the content.
        uint reviewDeadline; // The deadline for content being reviewed.
        uint currentResult; // The current result / points of reviewing.
        uint numberOfReviews; // The total amount of reviews.
        bool executed; // Checks if the content executed.
        bool contentPassed; // Checks if the content passed.
        mapping (address => bool) reviewed; // Checks the reviewers permission.
    }

    struct Member { // Address should be added to the struct.
        address memberAddress;
        string name; // Name of the member.
        uint registered; // Registration date.
        Account privilege; // Account privilege.
    }

    // Allows execution by the CEO only or the this contract.
    modifier ceoOnly {
        assert(member[msg.sender].privilege == Account.CEO
            || this == msg.sender);
        _;
    }

    // Allows execution by Members and CEO only.
    modifier memberOnly {
        assert(member[msg.sender].privilege == Account.Member
            || member[msg.sender].privilege == Account.CEO);
        _;
    }

    /**
    @dev the constructor of the organisation, which is executed when you first
    time setup.

    @param token the address of token being used in this organisation.
    @param pricePerContent the price per content.
    @param minutesForReview Sets the period of reviewing a content.
    @param minimumReviewsForContents minimal amount of reviews required for content.
    @param marginOfReviewsForMajority the amount of reviews for margin.
    @param tokenRewardForReview the token reward for reviewing.
    */
    function Organisation(
        Token token,
        uint pricePerContent,
        uint minutesForReview,
        uint minimumReviewsForContents,
        uint marginOfReviewsForMajority,
        uint tokenRewardForReview)
        public
        payable
    {
        // Add the organisation creator as the CEO.
        addMember(msg.sender, "Founder", Account.CEO);
        /*
        Function that changes organisation settings.
        Check the corresponding function for more information.
        */
        changeOrganisationSettings(
            token,
            pricePerContent,
            minutesForReview,
            minimumReviewsForContents,
            marginOfReviewsForMajority,
            tokenRewardForReview
        );
    }

    /**
    @dev changes the setting of the organisation.

    @param token the address of token being used in this organisation.
    @param pricePerContent the price per content.
    @param minutesForReview Sets the period of reviewing a content.
    @param minimumReviewsForContents minimal amount of reviews required for content.
    @param marginOfReviewsForMajority the amount of reviews for margin.
    @param tokenRewardForReview the token reward for reviewing.
    */
    function changeOrganisationSettings(
        Token token,
        uint pricePerContent,
        uint minutesForReview,
        uint minimumReviewsForContents,
        uint marginOfReviewsForMajority,
        uint tokenRewardForReview)
        public
        ceoOnly
    {
        tokenAddress = Token(token); // Set the token address.
        contentPrice = pricePerContent; // Set the content price.
        reviewPeriodInMinutes = minutesForReview; // Set the review period.
        minimumReviews = minimumReviewsForContents; // Set the minimum reviews.
        majorityMarginForContent = marginOfReviewsForMajority; // Set the majority margin.
        reviewReward = tokenRewardForReview; // Set the token reward.

        /*
        Activates the event listener with the corresponding name.
        */
        emit OrganisationSettings(
            tokenAddress,
            contentPrice,
            minimumReviews,
            majorityMarginForContent,
            reviewReward
        );
    }

    /*
    @dev the function adds a member to the organisation.

    @param targetMember the address being added.
    @param memberName the name of the member.
    @param accountType the privilege of the new member.
    */
    function addMember( // Need a second function that uses this function when ownership is transferred to this contract.
        address targetMember,
        string memberName,
        Account accountType)
        public
        ownerOnly
    {
        require(member[targetMember].memberAddress != targetMember); // Checks if the targetMember has an memberAddress.
        member[targetMember] = Member(targetMember, memberName, now, accountType); //Sets the targetMember to member mapping.
    }

    /*
    @dev enables members to add new content to the organisation by input title
    and description. The author will be automatically set to the function executor.

    @param contentTitle the title of the content.
    @param contentDescription description of the content.
    */
    function newContent(string contentTitle, string contentDescription)
        public
        memberOnly
    {
        tokenAddress.pay(msg.sender, contentPrice); // Uses the token address function to pay to this contract.
        uint contentID = contents.length++; // Set ID based on contents.length++.
        Content storage c = contents[contentID]; // Creates content struct that holds the content information.
        c.publisherAddress = msg.sender; // Set the publisher address.
        c.author = member[msg.sender].name; // Set the author of the content.
        c.title = contentTitle; // Set the content title.
        c.description = contentDescription; // Set the description of the content.
        c.reviewDeadline = now + reviewPeriodInMinutes * 1 minutes; // Deadline for reviewing content.
        c.numberOfReviews = 0; // Amount of reviews.
        c.executed = false; // Checks if the content is executed.
        c.contentPassed = false; // Checks if content passed the criterias.

        emit ContentAdded(contentID, c.author, c.title, c.description); // Event listener activated.
        numberOfContents = contentID+1; // Add the total number of content in organisation with 1.
    }

    /*
    @dev review function that is being used to review and award the reviewer

    @param contentNumber the number of the content.
    @param supportsContent bool that determines support for the content.
    @param justificationText additional text that the reviewer wants to add.
    */
    function reviewContent(
        uint contentNumber,
        bool supportsContent,
        string justificationText
    )
        public
        memberOnly
    {
        Content storage c = contents[contentNumber]; // Checks a content based on number.
        require(now < c.reviewDeadline); // Checks if time is within deadline.
        require(c.publisherAddress != msg.sender); // Checks that the reviwer is not the publisher.
        require(c.reviewed[msg.sender] == false); // Checks if the reviewer reviewed.
        c.reviewed[msg.sender] = true; // Sets review to true
        c.numberOfReviews++; // Increase reviews by one.
        if (supportsContent) {
            c.currentResult++; // If the content is supported, increase by one.
        } else {
            if(c.currentResult > 0) {
            c.currentResult--; // If the reviewer does not support, decrease by one.
            }
        }

        tokenAddress.transfer(msg.sender, reviewReward); // Transfer tokens from this contract to the function executor.
        emit Reviewed(contentNumber, supportsContent, msg.sender, justificationText); // Event listener activated based on the variables.
    }

    /*
    @dev executes content to see if it passed or not. It can only be activated after deadline.

    @param contentNumber the number of content being executed.
    */
    function executeContent(uint contentNumber) public
        memberOnly
    {
        Content storage c = contents[contentNumber]; // Sets a content based on number.
        require(now > c.reviewDeadline // Checks if the deadline has passed.
          && !c.executed // Checks if the content has been executed or not.
          && c.numberOfReviews > minimumReviews); // Checks if content passed minimum review criteria.
        if (c.currentResult >= majorityMarginForContent) { // Checks if the content passed a certain margin.
            c.executed = true; // Execute.
            c.contentPassed = true; // Passed.
        } else {
            c.executed = true; // Execute.
            c.contentPassed = false; // Failed.
        }

        emit ContentTallied(contentNumber, c.currentResult, c.numberOfReviews, c.contentPassed); // Content information being broadcasted.
    }

    /*
    @dev stake function that works with members only. It uses the tokens stake function.

    @param to the address being staked.
    */
    function stake(address to) public
        memberOnly
    {
        require(member[to].memberAddress == to); // Checks if the address of member equals the one to.
        tokenAddress.stake(to); // Stake based on the function on token address.
    }

    /*
    @dev purchase token based on token price set by token address.
    */
    function purchase() // Does not give the exact amount because float doesn't exist.
        public
        memberOnly
        payable
    {
        uint amount = div(msg.value, tokenAddress.tokenPriceInWei()); // Calculates the amount of token that will be bought.
        tokenAddress.buy(msg.sender, amount); // Buy function in token address.
    }

    /*
    @dev sell token based on amount set.

    @param amount the amount of token.
    */
    function sell(uint256 amount) public
        memberOnly
    {
        tokenAddress.sell(amount, msg.sender); // Sell the token to this contract.
        msg.sender.transfer(amount * 1 ether); // This contract send ether to the msg.sender.
    }

    /*
    @dev appoints a new ceo function.

    @param to the address given will be the new ceo.
    */
    function appointNewCEO(address to)
        public
        ceoOnly
    {
        require(member[to].memberAddress == to); // This function is broken. Checks if the address to is registered.
        check(to); // Checks if the address is valid.
        require(to != msg.sender); // Checks if the msg.sender is the address to.
        member[msg.sender].privilege = Account.Member; // Sets current CEO to Member.
        member[to].privilege = Account.CEO; // Address to gets appointed as CEO.
    }

    /*
    @dev kill the organisation function. msg.sender will receive all ether.
    */
    function kill() public ceoOnly { selfdestruct(msg.sender); }
}
