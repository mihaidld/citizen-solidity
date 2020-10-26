// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./CitizenERC20.sol";

//contract deployed at 

contract State {
    
    // Variables of state
    
    //adress of the state
    address payable state;
    
    CitizenERC20 public token;
    
    // Structs
    /// @dev struct Citizen
    struct Citizen{
         bool isAdmin; // false if the citizen is not an admin, true is an admin. When given nationality takes value false
         uint delayAdmin; // till when is the citizen with admin status an admin follwing his election (8 weeks)
         //bool canVote;// if not banned and nbOfTokens>0 true, else false
         uint nbOfCurrentAccountTokens; //100 full tokens (100 * 10**18 at registration), can be increased by salaries
         uint nbOfHealthInsuranceTokens;//10% from each salary, acces to it when admins declares him sick
         uint nbOfUnemployementTokens;//10% from each salary, acces to it when admins declares him unemployed 
         uint nbOfRetirementTokens;//10% from each salary, acces to it when age 67 
         uint retirementDate;
         uint age;
         bool isAlive;//true, after death false (the State gets his CTZ)
         bool isSick;//false, Admins can change it to true and then false again after some time
        // bool isBanned; //false at registration, true if banned by admins for 10 years
         uint delayBanned; // till when is the member banned following his punishment : block.timestamp + 10 * 52 * 1 weeks
         bool isWorking;//true when employed by a company, false when company lets him go
         
    }
    
    /// @dev struct Company
    struct Company{
        uint id; // company id
        uint nbOfEmployees; // 0 at registration, can be increased
        uint nbOfTokens; //5000 full tokens (5000 * 10**18 at registration), can be increased
        mapping (address => bool) employees; // list of company employees : true if an employee of this company, false if not
    }
    
    /// @dev struct Voting subject
    struct Election{
        uint id; // id of vote
        uint start; // when voting is possible (current mandate term - 1 week)
        uint term; // till when voting is possible (start + 1 week )
        //mapping (address => address ) forWhom; // mapping to associate for each citizen the citizen chosen as admin
        mapping (address => bool ) didVote; // mapping to check that an address can not vote twice for same vote subject id
        mapping (address => uint ) nbOfVotes; // mapping to associate for each citizen the number of votes received
    }
    
    /// @dev struct Mandate after admin elections
    struct Mandate{
        uint id; // id of mandate
        uint start; // when mandate starts after election results
        uint term; // till when mandate (start + 8 weeks )

    }
    
    /// @dev struct Proposal to be voted by admins
    struct Proposal{
        uint id; // id of proposal
        string question; // proposal question
        string description; // proposal description
        uint counterForVotes; // counter of votes `Yes`
        uint counterAgainstVotes; // counter of votes `No`
        uint counterBlankVotes; // counter of votes `Blank`
        //uint delay; // till when the proposal is active (proposal active for 1 week )
        mapping (address => bool) didVote; // mapping to check that an address can not vote twice for same proposal id
    }
    
    //Mappings 
    /// @dev mapping from an address to a Citizen
    mapping (address => Citizen) public citizens;
    
    /// @dev mapping from an address to a Company
    mapping (address => Company) public companies;

    /// @dev mapping from an id of an election to an Election
    mapping (uint => Election) public elections;

    /// @dev mapping from an id of a mandate to a Mandate
    mapping (uint => Mandate) public mandates;
    
    /// @dev mapping from an id of proposal to a Proposal
    mapping (uint => Proposal) public proposals;
    
    //Counters
    /// @dev counter for elections id incremented by each election
    uint private counterIdElection;
    
    /// @dev counter for mandates id incremented by each mandate
    uint private counterIdMandate;
    
    /// @dev counter for proposal id incremented by each proposal creation
    uint private counterIdProposal;
    
    /// @dev counter for company id incremented by each company registration
    uint private counterIdCompany;
    
    //Other variables
    /// @punishment options to be voted by admins: 0 -> Blank, 1 -> Yes, 2 -> No, other -> Invalid vote
    string public sentencesOptions = "0 -> Small, 1 -> Moderate, 2 -> Serious, 3 -> Treason";
    
    uint public retirementAge = 67;
    
    ///@dev awards and sentences
    uint private denomination = 10 ** uint256(token.decimals());
    uint private smallPunishment = 5 * denomination;
    uint private moderatePunishment = 50 * denomination;
    uint private seriousPunishment = 100 * denomination;
    uint private awardCitizenship = 100 * denomination;
    uint private awardRegistration = 5000 * denomination;
    uint private stakeAdmin = 100 * denomination;
    
    /// @dev punishment options: Yes, No, Blank using enum type
    enum Punishment { Small, Moderate, Serious, Treason} // variables of Punishment type with values: 0 -> Punishment.Small, 1 -> Punishment.Moderate, 2 -> Punishment.Serious, 3 -> Punishment.Treason
    
    /// @dev events for EVM log when registration
    event Award(address indexed _receiver, uint256 _awarded_tokens);
    event Penalty(address indexed _receiver, uint256 _remaining_tokens);
    
    constructor(address _citizenAddress ) public {
        token = CitizenERC20(_citizenAddress);//contract CitizenERC20 deployed at 0x4079ED1cF4752c8eDF54d55aF5d4f2aCBC26b957
        state = token.getOwner();
    }
    
    //Modifiers
    
    /// @dev modifier to check if admin
    modifier onlyAdmin (){
            require (citizens[msg.sender].isAdmin == true, "only admin can perform this action");
            _;
        }
    
    /// @dev modifier to check if citizen has at least 1 unit of CTZ   
    modifier onlyActiveCitizens (){
            require (citizens[msg.sender].nbOfCurrentAccountTokens > 0, "only citizens with at least 1 unit of CTZ can perform this action");
            _;
        }

    /// @dev modifier to check if citizen is not banned       
    modifier onlyAllowedCitizens (){
            require (citizens[msg.sender].delayBanned < block.timestamp, "only citizens not banned can perform this action");
            _;
        }
    
    /// @dev modifier to check if a citizen     
    modifier onlyAliveCitizens (){
            require (citizens[msg.sender].isAlive == true, "only citizens can perform this action");
            _;
        }
    
/*    function propose(string memory _question, string memory _description) public onlyAdmin onlyActiveMembers onlyWhitelistedMembers{
        counterIdProposal++;
        uint count = counterIdProposal;
        proposals [count] = Proposal(count, _question, _description, 0, 0, 0, block.timestamp + 1 weeks );
        
    }*/
    
    function elect (address _candidateAddress) public onlyAliveCitizens onlyActiveCitizens onlyAllowedCitizens{
        //verifier si votant n'est pas blacklisted et pas deja vote pour cette proposition
        require (block.timestamp >= mandates[counterIdMandate].term - 1 weeks, "too early to elect an admin");
        require (citizens[_candidateAddress].nbOfCurrentAccountTokens >= stakeAdmin, "candidate doesn't have enough CTZ to be elected");
        require (citizens[_candidateAddress].isAlive == true, "candidate is not a citizen");
        require (citizens[_candidateAddress].delayBanned < block.timestamp, "candidate is banned");
        require (elections[counterIdElection].didVote[msg.sender] == false, "citizen already voted for this proposal");
        elections[counterIdElection].nbOfVotes[_candidateAddress]++;
        elections[counterIdElection].didVote[msg.sender] = true;
    }

/*    function vote (uint _id, Option _voteOption ) public onlyActiveMembers onlyWhitelistedMembers{
        //verifier si votant n'est pas blacklisted et pas deja vote pour cette proposition
        require (proposals[_id].delay > block.timestamp, "proposal not active any more");
        require (proposals[_id].didVote[msg.sender] == false, "member already voted for this proposal");
        if (_voteOption == Option.Blank) {
            proposals[_id].counterBlankVotes++;
        } else if(_voteOption == Option.Yes) {
            proposals[_id].counterForVotes++;
        } else if(_voteOption == Option.No) {
            proposals[_id].counterAgainstVotes++;
        } else revert("Invalid vote");
        proposals[_id].didVote[msg.sender] = true;
    }*/

    function punish (address _sentenced, Punishment _option ) public onlyAdmin onlyAliveCitizens onlyActiveCitizens onlyAllowedCitizens{
        /// @dev addresses of state and not citizens cannot be banned
        require (_sentenced != state, "state cannot be punished");
        require (citizens[_sentenced].isAlive == true, "candidate is not alive");
        uint currentBalance = citizens[_sentenced].nbOfCurrentAccountTokens;
        if (_option == Punishment.Small) {
           currentBalance = currentBalance > smallPunishment ? currentBalance - smallPunishment : 0;
        } else if(_option == Punishment.Moderate) {
           currentBalance = currentBalance > moderatePunishment ? currentBalance - moderatePunishment : 0;
        } else if(_option == Punishment.Serious) {
           currentBalance = currentBalance > seriousPunishment ? currentBalance - seriousPunishment : 0;
        } else if(_option == Punishment.Treason) {
            currentBalance = 0;
            citizens[_sentenced].nbOfHealthInsuranceTokens = 0;
            citizens[_sentenced].nbOfUnemployementTokens = 0; 
            citizens[_sentenced].nbOfRetirementTokens = 0; 
            citizens[_sentenced].delayBanned = block.timestamp + 10 * 52 * 1 weeks;
        } else revert("Invalid punishment");
        citizens[_sentenced].nbOfCurrentAccountTokens = currentBalance;
        emit Penalty(_sentenced, currentBalance);
    }

    function pardon (address _beneficiary) public onlyAdmin onlyAliveCitizens onlyActiveCitizens onlyAllowedCitizens{
        citizens[_beneficiary].delayBanned = block.timestamp;
    }

    function becomeCitizen(uint _age) public payable{
        require (companies[msg.sender].id == 0, "companies cannot become citizens");
        require (citizens[msg.sender].retirementDate == 0, "citizens can not ask again for citizenship");
        uint retirementDate = block.timestamp + (retirementAge - _age) * 52 * 1 weeks;
        citizens[msg.sender] = Citizen(false, 0, awardCitizenship, 0, 0, 0, retirementDate, _age, true, false, 0, false);
        emit Award(msg.sender, awardCitizenship);
    }

    function registerCompany() public{
        require (citizens[msg.sender].retirementDate == 0, "citizens can not become companies");
        require (companies[msg.sender].id == 0, "only for companies not yet registered");
        counterIdCompany++;
        companies[msg.sender] = Company(counterIdCompany,  0, awardRegistration);
        emit Award(msg.sender, awardRegistration);
    }
}