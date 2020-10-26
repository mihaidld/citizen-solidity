// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./CitizenERC20.sol";

//contract deployed at 

contract State {
    
    // Variables of state
    
    //adress of the state
    address payable state;
    
    CitizenERC20 public token;
    
    /// @dev struct Citizen
    struct Citizen{
         bool isAdmin; // false if the citizen is not an admin, true is an admin. When given nationality takes value false
         uint delayAdmin; // till when is the citizen with admin status an admin follwing his election (8 weeks)
         bool canVote;// if not banned and nbOfTokens>0 true, else false
         uint256 nbOfCurrentAccountTokens; //100 full tokens (100 * 10**18 at registration), can be increased by salaries
         uint256 nbOfHealthInsuranceTokens;//10% from each salary, acces to it when admins declares him sick
         uint256 nbOfUnemployementTokens;//10% from each salary, acces to it when admins declares him unemployed 
         uint256 nbOfRetirementTokens;//10% from each salary, acces to it when age 67 
         uint age;
         bool isAlive;//true, after death false (the State gets his CTZ)
         bool isSick;//false, Admins can change it to true and then false again after some time
         bool isBanned; //false at registration, true if banned by admins for 10 years
         uint delayBanned; // till when is the member banned following his punishment : block.timestamp + 10 * 52 * 1 weeks
         bool isWorking;//true when employed by a company, false when company lets him go
         
    }
    
    /// @dev struct Company
    struct Company{
         uint256 nbOfEmployees; // 0 at registration, can be increased
         uint256 nbOfTokens; //5000 full tokens (5000 * 10**18 at registration), can be increased
         mapping (address => bool) employees; // list of company employees : true if an employee of this company, false if not
    }
    
    /// @dev struct Voting subject
    struct Vote{
        uint id; // id of vote
        string subject; // vote subject
        string description; // vote description
        uint delay; // till when voting is possible (elections for admin for 1 week )
        mapping (address => address ) forWhom; // mapping to associate for each citizen the citizen chosen as admin
        mapping (address => bool ) didVote; // mapping to check that an address can not vote twice for same vote subject id
        mapping (address => uint ) nbOfVotes; // mapping to associate for each citizen the number of votes received
    }

    constructor(address _citizenAddress ) public {
        token = CitizenERC20(_citizenAddress);//contract CitizenERC20 deployed at 0x4079ED1cF4752c8eDF54d55aF5d4f2aCBC26b957
        state = token.getOwner();
    }
    
}