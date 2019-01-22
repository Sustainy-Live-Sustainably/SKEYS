pragma solidity ^0.4.23;


contract ExternalStorage{

    mapping(bytes32 => uint) UIntStorage;

    function getUIntValue(bytes32 record) public constant returns (uint){
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) public
    {
        UIntStorage[record] = value;
    }

    mapping(bytes32 => string) StringStorage;

    function getStringValue(bytes32 record) public constant returns (string){
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string value) public
    {
        StringStorage[record] = value;
    }

    mapping(bytes32 => address) AddressStorage;

    function getAddressValue(bytes32 record) public constant returns (address){
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) public
    {
        AddressStorage[record] = value;
    }

    mapping(bytes32 => bytes) BytesStorage;

    function getBytesValue(bytes32 record) public constant returns (bytes){
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes value) public
    {
        BytesStorage[record] = value;
    }

    mapping(bytes32 => bool) BooleanStorage;

    function getBooleanValue(bytes32 record) public constant returns (bool){
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) public
    {
        BooleanStorage[record] = value;
    }

    mapping(bytes32 => int) IntStorage;

    function getIntValue(bytes32 record) public constant returns (int){
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) public
    {
        IntStorage[record] = value;
    }

    mapping(address => uint) VotesStorage;

    function getVoteValue(address record) public constant returns (uint){
        return VotesStorage[record];
    }

    function setVoteValue(address record, uint value) public
    {
        VotesStorage[record] = value;
    }
}


library ProposalsLibrary {
 //uint public numVotes;

  function getProposalCount(address _storageContract) public constant returns(uint256)
  {
    return ExternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked("ProposalCount")));
  }

  function addProposal(address _storageContract, bytes32 _name) public
  {
    uint idx = getProposalCount(_storageContract);
    //var numvotes = 0;
    bytes32 name_hash = keccak256(abi.encodePacked("proposal_name", idx));
    // byt
    bytes memory cmpl_title_hash = bytes(abi.encodePacked(_name));
    ExternalStorage(_storageContract).setBytesValue(name_hash, cmpl_title_hash);

    ExternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_name)), idx);
    ExternalStorage(_storageContract).setAddressValue(keccak256(abi.encodePacked(_name)), msg.sender);
    ExternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked("ProposalCount")), idx + 1);


  }
  function getProposalVotes(address _storageContract, bytes32 _name) public constant returns(uint){

    return ExternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked(_name)));
  }

   function getProposalIndex(address _storageContract, bytes32 _name)public constant returns(uint){
       // bytes32 name_hash = keccak256(abi.encodePacked("proposal_name", idx));
       return ExternalStorage(_storageContract).getUIntValue(keccak256(abi.encodePacked(_name)));

   }



   function getProposalbyIndex(address _storageContract, uint _index)public constant returns(bytes){
       // bytes32 name_hash = keccak256(abi.encodePacked("proposal_name", idx));
       return ExternalStorage(_storageContract).getBytesValue(keccak256(abi.encodePacked("proposal_name", _index)));

   }

   function VoteProposal(address _storageContract, bytes32 _name) public constant returns(uint) {
       uint numVotes = getProposalVotes( _storageContract, _name);
       ExternalStorage(_storageContract).setUIntValue(keccak256(abi.encodePacked(_name)), numVotes+1);
       return getProposalVotes( _storageContract, _name );
   }

  function setVoteAddress(address _storageContract, bytes32 _name) public constant returns (address){
      //uint initVote = ExternalStorage(_storageContract).getAddressValue(sha3(_name));
      ExternalStorage(_storageContract).setAddressValue(keccak256(abi.encodePacked(_name)), msg.sender);
      return  ExternalStorage(_storageContract).getAddressValue(keccak256(abi.encodePacked(_name)));
  }

  function registerVoter(address _storageContract, address _voter)  public{
      ExternalStorage(_storageContract).setVoteValue(_voter, 0);
  }

  function voteCandidate(address _storageContract, address _candidate) public returns (uint){
      uint init_vote = ExternalStorage(_storageContract).getVoteValue(_candidate);
      ExternalStorage(_storageContract).setVoteValue(_candidate, init_vote + 1);
      return ExternalStorage(_storageContract).getVoteValue(_candidate);
  }

  function getCandidateVotes(address _storageContract, address _candidate) public returns (uint){
       return ExternalStorage(_storageContract).getVoteValue(_candidate);

  }
}




contract BTM_Voting{
    using ProposalsLibrary for address;
    //address public _externalStorage = 0x95b0f8c33fa67a807c7b0750e418770b9355ec66;
    //address public _admin = 0x7e60b69435e6408e92ea2fbf5a047495911c6012;
    address public _storageSmartContract = 0x95b0F8C33Fa67a807c7B0750E418770B9355Ec66;
    uint public numProposals;
    //ProposalsLibrary public proposalslibrary;
    uint public numVotes;
    uint public proposalsVotes;
    address public admin;
    uint public noOfMembers;
    
    struct AggregateChoices {
        bytes32 proposalName;
        uint yes_counter;
        uint no_counter;
        uint abstain_counter;
    }
    
    struct VoterProposalChoice {
        bytes32 proposalName;
        string choice;
        address voter;
    }
    
    //AggregateChoice[] public aggregatechoices;
    event createProposal(string proposal_title, uint256 expiration_Time );
    event voteForProposal(string proposal_name, uint votesCast, address _voter);
    event voteForMember(address _candidate, uint numVoted);
    event addNewVoter(string _name, address _votingAddress);
    event deleteVoter(address _votingAddress);
    mapping(uint => uint256) public voteDeadline;
    mapping(address => uint ) public checkVoted;
    mapping(bytes32 => uint) public proposalVotes;
    mapping(bytes32 => uint) public proposalLookUp;
    mapping (address => uint)public candidateVotes;
    mapping (address => uint)public timesVoted;
    mapping (address => uint)public timesVotedMember;
    mapping (address=>bool) public members;
    mapping(bytes32 => uint256) public proposalEndTime;
    mapping(bytes32 => AggregateChoices) public mapProposalChoice;
    //mapping (uint => mapping(bytes32 => string)) public AggregateChoices;
    mapping (address => VoterProposalChoice ) public mapVoter;
    mapping(bytes32 => address) memberName;
    
    // add by santo
    mapping(string => mapping(address => address)) votedMapping;
    // end by santo
    
    
    constructor() public{
        //externalStorage = _externalStorage;
        admin = msg.sender;
    }
    
    
    modifier onlyMember(address _memberAddress) {
    require(members[_memberAddress] == true);
      _;
  }
  modifier onlyAdmin() {
   require(msg.sender == admin);
   _;
}
 
  function addMember(string _name, address _member) public {
      require(members[_member] == false);
      members[_member] = true;
      noOfMembers = noOfMembers + 1;
      checkVoted[_member] = numVotes;
      timesVoted[_member] = 0;
      memberName[keccak256(abi.encodePacked(_name))] = _member;
      emit addNewVoter(_name,  _member);
  }
 

  function removeMember(string _name) public onlyAdmin {
      address _member = memberName[keccak256(abi.encodePacked(_name))];
      require(members[_member] == true);
      members[_member] = false;
      noOfMembers = noOfMembers - 1;
      emit deleteVoter( _member);
  }
  
    function createNewProposal(string _name, uint256 _deadline) public onlyMember(msg.sender){
        require(msg.sender != address(0));
        require(_deadline > now);
        bytes32 name = keccak256(abi.encodePacked(_name));
        ProposalsLibrary.addProposal(_storageSmartContract, name);
        proposalLookUp[name] = ProposalsLibrary.getProposalCount(_storageSmartContract);
        proposalEndTime[name] = _deadline;
        numProposals = numProposals + 1;
        emit createProposal(_name, _deadline);
    }
    
     function getProposalEndTime(string _name) onlyMember(msg.sender) public constant returns(uint256){
         bytes32 name = keccak256(abi.encodePacked(_name));
         return proposalEndTime[name];
     }

    function getProposalVoted(address _voter) onlyMember(_voter) public constant returns(uint256){
        return checkVoted[_voter];
     }

     function getTimesVoted(address _voter) onlyMember(msg.sender) public constant returns(uint256){
        return timesVoted[_voter];
     }
     


    function voteProposal(string _name, uint _choice)onlyMember(msg.sender) public{
        require(msg.sender != address(0));
        bytes32 name = keccak256(abi.encodePacked(_name));
        //uint currentIndex = ProposalsLibrary.getProposalIndex(_storageSmartContract, name);
        require(proposalEndTime[name] >= now);
        require(timesVoted[msg.sender] < numProposals); 
        
        // add by santo
        require(votedMapping[_name][msg.sender] == address(0));
        // end        

        if (_choice == 1){
            ProposalsLibrary.VoteProposal(_storageSmartContract, name);
            timesVoted[msg.sender] = timesVoted[msg.sender] + 1;
            mapProposalChoice[name].proposalName = name;
            mapProposalChoice[name].yes_counter = mapProposalChoice[name].yes_counter + 1;
            mapVoter[msg.sender].proposalName = name;
            mapVoter[msg.sender].choice = "YES";
            mapVoter[msg.sender].voter = msg.sender;
            proposalVotes[name] = proposalVotes[name] + 1;
        }
        if (_choice == 2){
            ProposalsLibrary.VoteProposal(_storageSmartContract, name);
            timesVoted[msg.sender] = timesVoted[msg.sender] + 1;
            mapProposalChoice[name].proposalName = name;
            mapProposalChoice[name].no_counter = mapProposalChoice[name].no_counter + 1;
            mapVoter[msg.sender].proposalName = name;
            mapVoter[msg.sender].choice = "NO";
            mapVoter[msg.sender].voter = msg.sender;
            //proposalVotes[name] = proposalVotes[name] + 1;
            proposalVotes[name] = proposalVotes[name] + 1;
        }
        if (_choice == 3){
            //ProposalsLibrary.VoteProposal(_storageSmartContract, name);
            timesVoted[msg.sender] = timesVoted[msg.sender] + 1;
            mapProposalChoice[name].proposalName = name;
            mapProposalChoice[name].abstain_counter = mapProposalChoice[name].abstain_counter + 1;
            mapVoter[msg.sender].proposalName = name;
            mapVoter[msg.sender].choice = "ABSTAIN";
            mapVoter[msg.sender].voter = msg.sender;
            proposalVotes[name] = proposalVotes[name] + 1;
        }
        
       // add by santo
        votedMapping[_name][msg.sender] = msg.sender;
        // end
        emit voteForProposal(_name, proposalVotes[name], msg.sender);
    }
    
    function startMemberVote(uint256 _deadline)onlyAdmin public {
        require(_deadline > now);
        numVotes = numVotes + 1;
        voteDeadline[numVotes] = _deadline;
        //checkVoted[numVotes] = msg.sender;
    }
    function voteMember(string _name)onlyMember(msg.sender) public {
        require(msg.sender != address(0));
        require(voteDeadline[numVotes] >= now && checkVoted[msg.sender] < numVotes);
        checkVoted[msg.sender] =  checkVoted[msg.sender] + 1;
        address _member = memberName[keccak256(abi.encodePacked(_name))];
        timesVotedMember[_member] = timesVotedMember[_member] + 1;
        candidateVotes[memberName[keccak256(abi.encodePacked(_name))]] = candidateVotes[memberName[keccak256(abi.encodePacked(_name))]] + 1;
        //numVotes = numVotes + 1;
        emit voteForMember(memberName[keccak256(abi.encodePacked(_name))],candidateVotes[memberName[keccak256(abi.encodePacked(_name))]]);    
        }
    
    function getMemberVotes(address _candidate)onlyMember(_candidate)public constant returns ( address, uint){
      uint totalVotes = candidateVotes[_candidate];
      return (_candidate, totalVotes);
    }
    
    function getProposalDetails(string _name)onlyMember(msg.sender)public constant returns(uint,uint,uint){
        bytes32 name = keccak256(abi.encodePacked(_name));
        //var IndexOfProposal = ProposalsLibrary.getProposalIndex(_storageSmartContract, name
         uint yeses = mapProposalChoice[name].yes_counter;
         uint noos = mapProposalChoice[name].no_counter;
         uint abstains = mapProposalChoice[name].abstain_counter;
         return(yeses, noos, abstains);
    }

    function getYesCount(string _name)onlyMember(msg.sender)public constant returns(uint){
         bytes32 name = keccak256(abi.encodePacked(_name));
         return mapProposalChoice[name].yes_counter;
    }
    function getNoCount(string _name)onlyMember(msg.sender)public constant returns(uint){
         bytes32 name = keccak256(abi.encodePacked(_name));
         return mapProposalChoice[name].no_counter;
    }
    function getAbstainCount(string _name)onlyMember(msg.sender)public constant returns(uint){
         bytes32 name = keccak256(abi.encodePacked(_name));
         return mapProposalChoice[name].abstain_counter;
    }
}
