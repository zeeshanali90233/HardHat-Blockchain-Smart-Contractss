// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ElectionCommission {
    address public chairPerson;
    enum Status {
        NotCreated,
        created,
        votingStarted,
        completed
    }
    struct electionDetails {
        string e_name;
        string e_email;
        Status status;
    }
    string currentElectionEmail;

    mapping(string => electionDetails) internal Elections;

    constructor() {
        chairPerson = msg.sender;
    }

    modifier onlyChairPerson() {
        require(chairPerson == msg.sender, "Access denied");
        _;
    }

    modifier checkUniqueElec(string memory _eemail) {
        require(
            Elections[_eemail].status == Status.NotCreated,
            "Election at this email already exists"
        );
        _;
    }

    event ElectionCreate(string _eemail);

    function createBallot(
        string memory _ename,
        string memory _eemail
    ) external onlyChairPerson checkUniqueElec(_ename) {
        require(
            Elections[_eemail].status == Status.NotCreated,
            "Election already exists"
        );
        Elections[_eemail] = electionDetails(_ename, _eemail, Status.created);
        currentElectionEmail = _eemail;
        emit ElectionCreate(_eemail);
    }

    event electionStart(string _eemail);

    function startElection(string memory _eemail) external onlyChairPerson {
        require(
            Elections[_eemail].status == Status.created &&
                Elections[_eemail].status != Status.NotCreated,
            "Not allowed"
        );
        Elections[_eemail].status = Status.votingStarted;
        currentElectionEmail = _eemail;
        emit electionStart(_eemail);
    }

    event electionEnd(string _eemail);

    function endElection(string memory _eemail) external onlyChairPerson {
        Elections[_eemail].status = Status.completed;
        currentElectionEmail = "";
        emit electionEnd(_eemail);
    }
}

contract Ballot is ElectionCommission {
    uint256 totalVoters;
    uint256 totalCandidates;

    enum Roles {
        visitor,
        voter,
        manager,
        candidate
    }

    struct Voter {
        string name;
        Roles role;
        bool isBlocked;
    }

    struct Candidate {
        string name;
        Roles role;
        string partyNumber;
        bool isBlocked;
    }

    struct Party {
        string name;
        string partyNumber;
        bool isExists;
        bool isBlocked;
    }

    mapping(string => Voter) voters;
    mapping(string => Candidate) candidates;
    mapping(string => Party) parties;

    mapping(address => Roles) users;

    // Voter voted or not
    mapping(string => mapping(address => bool)) isVoterVoted;

    // Party Votes
    mapping(string => mapping(string => uint256)) PartyVotes;

    // member Votes
    mapping(string => mapping(string => uint256)) CandidateVotes;

    constructor() {
        totalVoters = 0;
        totalCandidates = 0;
    }

    modifier onlyAdmin() {
        require(
            (msg.sender == chairPerson || users[msg.sender] == Roles.manager),
            "Access denies"
        );
        _;
    }

    modifier isElectionActive() {
        require(
            Elections[currentElectionEmail].status == Status.votingStarted,
            "No election is on going"
        );
        _;
    }

    function addVoter(
        string memory _cnic,
        string memory _name
    ) external onlyAdmin {
        require(voters[_cnic].role == Roles.visitor, "Voter already exists");
        voters[_cnic] = Voter(_name, Roles.voter, false);
        totalVoters++;
    }

    function getVoter(string memory _cnic) public view returns (string memory) {
        return (voters[_cnic].name);
    }

    function getTotalVoters(
        string memory _eemail
    ) public view returns (uint256) {
        require(
            Elections[_eemail].status == Status.votingStarted,
            "Currently No Ellection is going on"
        );
        return (totalVoters);
    }

    function getTotalCandidates(
        string memory _eemail
    ) public view returns (uint256) {
        require(
            Elections[_eemail].status == Status.votingStarted,
            "Currently No Ellection is going on"
        );
        return (totalCandidates);
    }

    event PartyAdd(string _name, string _partyNumber);

    function addParty(
        string memory _name,
        string memory _partyNumber
    ) external onlyChairPerson {
        require(!(parties[_partyNumber].isExists), "Party already exists");

        parties[_partyNumber] = Party(_name, _partyNumber, true, false);
        emit PartyAdd(_name, _partyNumber);
    }

    event CandidateAdd(string _cnic, string _partyNumber);

    function addCandidate(
        string memory _cnic,
        string memory _name,
        string memory _partyNumber
    ) external onlyChairPerson {
        require(
            candidates[_cnic].role != Roles.candidate,
            "Candidate already exists"
        );
        require(parties[_partyNumber].isExists, "Party not exists");

        candidates[_cnic] = Candidate(
            _name,
            Roles.candidate,
            _partyNumber,
            false
        );
        totalCandidates++;
        emit CandidateAdd(_cnic, _partyNumber);
    }

    function getCandidate(
        string memory _cnic
    ) external view returns (string memory, Roles, string memory) {
        return (
            candidates[_cnic].name,
            candidates[_cnic].role,
            candidates[_cnic].partyNumber
        );
    }

    event candidateBlocked(string _cnic);

    function blockCandidate(string memory _cnic) external onlyChairPerson {
        require(
            candidates[_cnic].role != Roles.visitor,
            "Candidate not exists"
        );
        candidates[_cnic].isBlocked = true;
        emit candidateBlocked(_cnic);
    }

    event voterBlocked(string _cnic);

    function blockVisitor(string memory _cnic) external onlyChairPerson {
        require(voters[_cnic].role != Roles.visitor, "Voters not exists");
        voters[_cnic].isBlocked = true;
        emit voterBlocked(_cnic);
    }

    event voterUnBlocked(string _cnic);

    function unBlockVisitor(string memory _cnic) external onlyChairPerson {
        require(voters[_cnic].role != Roles.visitor, "Voters not exists");
        voters[_cnic].isBlocked = false;
        emit voterUnBlocked(_cnic);
    }

    event candidateUnBlocked(string _cnic);

    function unBlockCandidate(string memory _cnic) external onlyChairPerson {
        require(
            candidates[_cnic].role != Roles.visitor,
            "Candidates not exists"
        );
        candidates[_cnic].isBlocked = false;
        emit candidateUnBlocked(_cnic);
    }

    event vote(string _partyNumber, string _candidateCnic);

    function isCastedVote(
        string memory eemail
    ) public view onlyAdmin returns (bool) {
        return (isVoterVoted[eemail][msg.sender]);
    }

    function doVote(
        string memory _partyNumber,
        string memory _candidateCnic
    ) public isElectionActive {
        require(
            !(isVoterVoted[currentElectionEmail][msg.sender]),
            "Already Voted"
        );

        isVoterVoted[currentElectionEmail][msg.sender] = true;
        PartyVotes[currentElectionEmail][_partyNumber] += 1;
        CandidateVotes[currentElectionEmail][_candidateCnic] += 1;
        emit vote(_partyNumber, _candidateCnic);
    }
}
