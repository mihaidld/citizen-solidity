// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./CitizenERC20.sol";

//contract deployed at

contract Government {
    // Variables of state

    //address of the sovereign
    address payable public sovereign;

    //national token
    CitizenERC20 public token;

    // price of 1 full CTZ (10^18 units of token) in wei;
    uint256 public price;

    /// @dev struct Citizen
    struct Citizen {
        bool isAlive; //true, after death false (the sovereign gets his balance)
        address employer; //company employing the citizen
        bool isWorking; //set by an admin
        bool isSick; //set by an admin
        uint256 nbVotes; //during elections increased if candidate receives votes. If >= 5 named admin and nbVotes is reset to 0
        uint256 termAdmin; // till when a citizen is an admin (8 weeks from election)
        uint256 retirementDate;
        uint256 termBanned; // till when is the member banned following punishment for treason: block.timestamp + 10 * 52 * 1 weeks
        uint256 nbOfCurrentAccountTokens; //100 full tokens (100 * 10**18 at registration), can be increased by salaries
        uint256 nbOfHealthInsuranceTokens; //10% from each salary, acces to it when admins declares him sick
        uint256 nbOfUnemploymentTokens; //10% from each salary, acces to it when admins declares him unemployed
        uint256 nbOfRetirementTokens; //10% from each salary, acces to it when age 67
    }

    /// @dev struct Proposal to be voted by admins
    struct Proposal {
        uint256 id; // id of proposal
        string question; // proposal question
        string description; // proposal description
        uint256 counterForVotes; // counter of votes `Yes`
        uint256 counterAgainstVotes; // counter of votes `No`
        uint256 counterBlankVotes; // counter of votes `Blank`
        mapping(address => bool) didVote; // mapping to check that an address can not vote twice for same proposal id
    }

    /// @dev mapping from an address to a Citizen
    mapping(address => Citizen) public citizens;

    /// @dev mapping to register a company: companies[address] = true
    mapping(address => bool) public companies;

    /// @dev mapping to check last date of vote (so an address can not vote twice during a mandate)
    mapping(address => uint256) dateVote;

    /// @dev mapping from an id of proposal to a Proposal
    mapping(uint256 => Proposal) public proposals;

    /// @dev counter for proposal id incremented by each proposal creation
    uint256 private counterIdProposal;

    //Other variables
    uint256 public retirementAge = 67;
    uint256 private currentMandateTerm;
    uint256 private mandateDuration = 8 weeks;
    uint256 private electionsDuration = 1 weeks;
    uint256 private nbMinimumVotesToGetElected = 5;
    uint256 private denomination = 10**uint256(token.decimals());
    uint256 private smallPunishment = 5 * denomination;
    uint256 private moderatePunishment = 50 * denomination;
    uint256 private seriousPunishment = 100 * denomination;
    uint256 private awardCitizenship = 100 * denomination;
    uint256 private stakeAdmin = 100 * denomination;
    uint256 private banishment = 10 * 52 weeks;

    /// @notice options to be voted by admins: 0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason, other -> Invalid choice
    string
        public howToPunish = "0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason";
    /// @dev punishment options using enum type: 0 -> Punishment.Small, 1 -> Punishment.Moderate, 2 -> Punishment.Serious, 3 -> Punishment.Treason
    enum Punishment {Small, Moderate, Serious, Treason}

    /// @notice instructions to vote by admins: 0 -> Blank, 1 -> Yes, 2 -> No, other -> Invalid vote
    string public howToVote = "0 -> Blank, 1 -> Yes, 2 -> No";
    /// @dev vote options using enum type: 0 -> Option.Blank, 1 -> Option.Yes, 2 -> Option.No
    enum Option {Blank, Yes, No}

    /// @notice instructions to change health status by admins: 0 -> Died, 1 -> Healthy, 2 -> Sick, other -> Invalid choice
    string public healthStatusOptions = "0 -> Died, 1 -> Healthy, 2 -> Sick";
    /// @dev health status options using enum type: 0 -> HealthStatus.Died, 1 -> HealthStatus.Healthy, 2 -> HealthStatus.Sick
    enum HealthStatus {Died, Healthy, Sick}

    constructor(
        address _tokenAddress,
        address payable _sovereign,
        uint256 _price
    ) public {
        token = CitizenERC20(_tokenAddress); //contract CitizenERC20 deployed at 0xB1ee0c20301F72847cCCfAa60b4bB76fC546372B
        //sovereign = token.getOwner();
        sovereign = _sovereign;
        //price for 1 full CTZ (10^18 tokens) in wei : 10**16 or 0.01 ether or 10000000000000000
        price = _price;
    }

    //Modifiers

    // A modifier for checking if the msg.sender is the sovereign (e.g. president, king)
    modifier onlySovereign() {
        require(
            msg.sender == sovereign,
            "ERC20: Only sovereign can perform this action"
        );
        _;
    }

    /// @dev modifier to check if admin
    modifier onlyAdmin() {
        require(
            citizens[msg.sender].termAdmin >= block.timestamp,
            "only admin can perform this action"
        );
        _;
    }

    /// @dev modifier to check if citizen has at least 1 unit of CTZ
    modifier onlySolventCitizens() {
        require(
            citizens[msg.sender].nbOfCurrentAccountTokens > 0,
            "only citizens with at least 1 unit of CTZ in current account can perform this action"
        );
        _;
    }

    /// @dev modifier to check if citizen is not banned
    modifier onlyAllowedCitizens() {
        require(
            citizens[msg.sender].termBanned < block.timestamp,
            "only citizens not banned can perform this action"
        );
        _;
    }

    /// @dev modifier to check is an address points to a citizen or an alive one
    modifier onlyAliveCitizens() {
        require(
            citizens[msg.sender].isAlive == true,
            "only citizens can perform this action"
        );
        _;
    }
    /// @dev modifier to check if citizen's age is > 18
    modifier onlyAdults() {
        require(
            citizens[msg.sender].retirementDate <
                block.timestamp + (retirementAge - 18) * 52 weeks,
            "only adults can perform this action"
        );
        _;
    }

    /// @dev modifier to check if company registered
    modifier onlyCompanies() {
        require(
            companies[msg.sender] == true,
            "Only a company can perform this action"
        );
        _;
    }

    // Election stage

    /// @dev function for citizens to elect admins, election is possible during last week of current mandate term to insure continuity of public service
    function elect(address _candidateAddress)
        public
        onlyAdults
        onlyAliveCitizens
        onlySolventCitizens
        onlyAllowedCitizens
    {
        require(
            citizens[_candidateAddress].retirementDate <
                block.timestamp + (retirementAge - 18) * 52 weeks,
            "only adults can be elected"
        );
        require(
            block.timestamp >= currentMandateTerm - 1 weeks,
            "too early to elect"
        );
        require(block.timestamp <= currentMandateTerm, "too late to elect");
        require(
            citizens[_candidateAddress].nbOfCurrentAccountTokens >= stakeAdmin,
            "candidate doesn't have enough CTZ to be elected"
        );
        require(
            citizens[_candidateAddress].isAlive == true,
            "candidate is not a citizen"
        );
        require(
            citizens[_candidateAddress].termBanned < block.timestamp,
            "candidate is banned"
        );
        require(
            dateVote[msg.sender] < currentMandateTerm - 8 weeks,
            "citizen already voted for this election"
        );
        citizens[_candidateAddress].nbVotes++;
        dateVote[msg.sender] = block.timestamp;
    }

    /// @dev function for the sovereign to set new mandate term
    function updateMandate() public onlySovereign {
        currentMandateTerm = block.timestamp + mandateDuration;
    }

    /// @dev function for the sovereign to name admins following election results
    function setAdmin(address _adminAddress) public onlySovereign {
        require(
            citizens[_adminAddress].nbVotes >= nbMinimumVotesToGetElected,
            "candidate has not received the minimum number of votes"
        );
        require(
            citizens[_adminAddress].nbOfCurrentAccountTokens >= stakeAdmin,
            "candidate doesn't have enough CTZ to be elected"
        );
        require(
            citizens[_adminAddress].isAlive == true,
            "candidate is not a citizen"
        );
        require(
            citizens[_adminAddress].termBanned < block.timestamp,
            "candidate is banned"
        );
        citizens[_adminAddress].termAdmin = currentMandateTerm;
        citizens[_adminAddress].nbVotes = 0; //reset to 0 number of votes
    }

    //For Admin : government affairs

    /// @dev function to propose new policy
    function proposePolicy(string memory _policy, string memory _description)
        public
        onlyAdmin
    {
        counterIdProposal++;
        uint256 count = counterIdProposal;
        proposals[count] = Proposal(count, _policy, _description, 0, 0, 0);
    }

    /// @dev function to vote on policy proposals
    function votePolicy(uint256 _id, Option _voteOption) public onlyAdmin {
        require(
            proposals[_id].didVote[msg.sender] == false,
            "admin already voted for this proposal"
        );
        if (_voteOption == Option.Blank) {
            proposals[_id].counterBlankVotes++;
        } else if (_voteOption == Option.Yes) {
            proposals[_id].counterForVotes++;
        } else if (_voteOption == Option.No) {
            proposals[_id].counterAgainstVotes++;
        } else revert("Invalid vote");
        proposals[_id].didVote[msg.sender] = true;
    }

    /// @dev function to give sentences
    function punish(address _sentenced, Punishment _option) public onlyAdmin {
        /// @dev addresses of sovereign and not a citizen cannot be punished
        require(_sentenced != sovereign, "sovereign cannot be punished");
        require(
            citizens[_sentenced].isAlive == true,
            "impossible punishment: not an alive citizen"
        );
        uint256 currentBalance = citizens[_sentenced].nbOfCurrentAccountTokens;
        if (_option == Punishment.Small) {
            currentBalance = currentBalance > smallPunishment
                ? currentBalance - smallPunishment
                : 0;
        } else if (_option == Punishment.Moderate) {
            currentBalance = currentBalance > moderatePunishment
                ? currentBalance - moderatePunishment
                : 0;
        } else if (_option == Punishment.Serious) {
            currentBalance = currentBalance > seriousPunishment
                ? currentBalance - seriousPunishment
                : 0;
        } else if (_option == Punishment.Treason) {
            currentBalance = 0;
            citizens[_sentenced].nbOfHealthInsuranceTokens = 0;
            citizens[_sentenced].nbOfUnemploymentTokens = 0;
            citizens[_sentenced].nbOfRetirementTokens = 0;
            citizens[_sentenced].termBanned = block.timestamp + banishment;
            token.transferFrom(
                _sentenced,
                sovereign,
                token.balanceOf(_sentenced)
            );
            if (citizens[_sentenced].termAdmin > block.timestamp) {
                citizens[_sentenced].termAdmin = block.timestamp;
            }
        } else revert("Invalid punishment");
        citizens[_sentenced].nbOfCurrentAccountTokens = currentBalance;
    }

    /// @dev function for sovereign to pardon citizens before their banishment term
    function pardon(address _beneficiary) public onlySovereign {
        citizens[_beneficiary].termBanned = block.timestamp;
    }

    /// @dev function to change a citizen's health status
    function changeHealthStatus(address _concerned, HealthStatus _option)
        public
        onlyAdmin
    {
        if (_option == HealthStatus.Died) {
            citizens[_concerned].isAlive = false;
            //if the citizen is an admin
            if (citizens[_concerned].termAdmin > block.timestamp) {
                citizens[_concerned].termAdmin = block.timestamp;
            }
            citizens[_concerned].nbOfCurrentAccountTokens = 0;
            citizens[_concerned].nbOfHealthInsuranceTokens = 0;
            citizens[_concerned].nbOfUnemploymentTokens = 0;
            citizens[_concerned].nbOfRetirementTokens = 0;
            token.transferFrom(
                _concerned,
                sovereign,
                token.balanceOf(_concerned)
            );
        } else if (_option == HealthStatus.Healthy) {
            citizens[_concerned].isSick = false;
        } else if (_option == HealthStatus.Sick) {
            citizens[_concerned].isSick = true;
            citizens[_concerned]
                .nbOfCurrentAccountTokens += citizens[_concerned]
                .nbOfHealthInsuranceTokens;
            citizens[_concerned].nbOfHealthInsuranceTokens = 0;
        } else revert("Invalid health status choice");
    }

    /// @dev function to change a citizen's employment status
    function changeEmploymentStatus(address _concerned) public onlyAdmin {
        if (citizens[_concerned].isWorking == true) {
            citizens[_concerned].isWorking = false;
            citizens[_concerned]
                .nbOfCurrentAccountTokens += citizens[_concerned]
                .nbOfUnemploymentTokens;
            citizens[_concerned].nbOfUnemploymentTokens = 0;
        } else {
            citizens[_concerned].isWorking = true;
        }
    }

    /// @dev function to register a company
    function registerCompany(address _companyAddress) public onlyAdmin {
        require(
            companies[_companyAddress] == false,
            "company is already registered"
        );
        companies[_companyAddress] = true;
    }

    // For citizens : actions

    /// @dev function to get citizenship
    function becomeCitizen(
        uint256 _age,
        bool _isWorking,
        bool _isSick
    ) public {
        require(
            citizens[msg.sender].retirementDate == 0,
            "citizens can not ask again for citizenship"
        );
        uint256 retirementDate = retirementAge >= _age
            ? block.timestamp + (retirementAge - _age) * 52 weeks
            : block.timestamp;
        token.transferFrom(sovereign, msg.sender, awardCitizenship);
        citizens[msg.sender] = Citizen(
            true,
            address(0),
            _isWorking,
            _isSick,
            0,
            0,
            retirementDate,
            0,
            awardCitizenship,
            0,
            0,
            0
        );
    }

    /// @dev function to ask for retirement
    function getRetired() public onlyAliveCitizens onlyAllowedCitizens {
        require(
            citizens[msg.sender].retirementDate <= block.timestamp,
            "retirement possible only at 67"
        );
        citizens[msg.sender].isWorking = false;
        citizens[msg.sender].nbOfCurrentAccountTokens += citizens[msg.sender]
            .nbOfRetirementTokens;
        citizens[msg.sender].nbOfRetirementTokens = 0;
    }

    // For companies : actions

    /// @dev function for a company to buy CTZ
    // nbTokens is the number of units of a full token (e.g. 1 CTZ = 10^18 nbTokens)
    function buyTokens(uint256 nbTokens)
        public
        payable
        onlyCompanies
        returns (bool)
    {
        require(msg.value > 0, "minimum 1 wei");
        //check if minimum 100 units of token bought since 1 wei = 100 units
        require(
            nbTokens >= (10**uint256(token.decimals()) / price),
            "minimum 100 tokens"
        );
        //check if enough ether for nbTokens
        require(
            (nbTokens * price) / 10**uint256(token.decimals()) <= msg.value,
            "not enough Ether to purchase this number of tokens"
        );
        uint256 _realPrice = (nbTokens * price) / 10**uint256(token.decimals());
        uint256 _remaining = msg.value - _realPrice;
        token.transferFrom(sovereign, msg.sender, nbTokens);
        sovereign.transfer(_realPrice);
        if (_remaining > 0) {
            msg.sender.transfer(_remaining);
        }
        return true;
    }

    /// @dev function to recruit a citizen
    function recruit(address _employee) public onlyCompanies {
        require(
            citizens[_employee].employer != msg.sender,
            "employee already working for this company"
        );
        citizens[_employee].employer = msg.sender;
    }

    /// @dev function for a company to pay salaries
    function paySalary(address payable _employee, uint256 _amount)
        public
        onlyCompanies
    {
        require(
            citizens[_employee].employer == msg.sender,
            "not an employee of this company"
        );
        require(
            token.balanceOf(msg.sender) >= _amount,
            "company balance is less than the amount"
        );
        token.transfer(_employee, _amount);
        citizens[_employee].nbOfHealthInsuranceTokens = _amount / 10;
        citizens[_employee].nbOfUnemploymentTokens = _amount / 10;
        citizens[_employee].nbOfRetirementTokens = _amount / 10;
        citizens[_employee].nbOfCurrentAccountTokens =
            token.balanceOf(_employee) -
            citizens[_employee].nbOfHealthInsuranceTokens -
            citizens[_employee].nbOfUnemploymentTokens -
            citizens[_employee].nbOfRetirementTokens;
    }
}
