// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract FreelanceManagementPlatform {
    // Author@SHIJUN JIANG, HKUST, 21134775
    
    struct Project {
        address client; // Client who creates the project
        address freelancer; // Freelancer assigned to the project
        uint256[] milestones; // Payment amounts for each milestone
        string[] descriptions; // Descriptions for each milestone
        bool[] completedMilestones; // Status of each milestone
        bool projectComplete; // Whether the project is complete
        uint256 escrowedAmount; // Total funds escrowed for the project
    }

    // Struct representing a dispute
    struct Dispute {
        uint256 projectId; // ID of the disputed project
        uint256 milestoneIndex; // Index of the disputed milestone
        address[] voters; // Addresses of voters in the dispute
        mapping(address => bool) hasVoted; // Whether an address has voted
        uint256 votesForCompletion; // Votes for milestone completion
        uint256 votesAgainstCompletion; // Votes against milestone completion
        bool resolved; // Whether the dispute is resolved
    }

    // Mappings for storing projects and disputes
    mapping(uint256 => Project) public projects;
    mapping(uint256 => Dispute) public disputes;
    uint256 public projectCount; // Total number of projects
    uint256 public disputeCount; // Total number of disputes

    // Events to log important actions
    event ProjectCreated(uint256 projectId, address client, address freelancer);
    event MilestoneSubmitted(uint256 projectId, uint256 milestoneIndex);
    event MilestoneApproved(uint256 projectId, uint256 milestoneIndex);
    event DisputeCreated(uint256 disputeId, uint256 projectId, uint256 milestoneIndex);
    event DisputeResolved(uint256 disputeId, bool milestoneApproved);

    // Modifier to restrict access to the client of a project
    modifier onlyClient(uint256 projectId) {
        require(msg.sender == projects[projectId].client, "Only client can call this function");
        _;
    }

    // Modifier to restrict access to the freelancer of a project
    modifier onlyFreelancer(uint256 projectId) {
        require(msg.sender == projects[projectId].freelancer, "Only freelancer can call this function");
        _;
    }

    // Constructor to initialize the contract (made payable to support deployment with ETH)
    constructor() payable {}

    // Function to deposit funds into the contract
    function depositToEscrow() public payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
    }

    // Function to create a new project
    function createProject(
        address freelancer,
        uint256[] memory milestones,
        string[] memory descriptions
    ) public payable {
        require(msg.value > 0, "Escrow amount must be provided");
        require(milestones.length == descriptions.length, "Milestones and descriptions must match");

        projects[projectCount] = Project({
            client: msg.sender,
            freelancer: freelancer,
            milestones: milestones,
            descriptions: descriptions,
            completedMilestones: new bool[](milestones.length),
            projectComplete: false,
            escrowedAmount: msg.value
        });

        emit ProjectCreated(projectCount, msg.sender, freelancer);
        projectCount++;
    }

    // Function for the freelancer to submit a milestone
    function submitMilestone(uint256 projectId, uint256 milestoneIndex) public onlyFreelancer(projectId) {
        require(milestoneIndex < projects[projectId].milestones.length, "Invalid milestone index");
        require(!projects[projectId].completedMilestones[milestoneIndex], "Milestone already submitted");

        emit MilestoneSubmitted(projectId, milestoneIndex);
    }

    // Function for the client to approve a milestone
    function approveMilestone(uint256 projectId, uint256 milestoneIndex) public onlyClient(projectId) {
        require(milestoneIndex < projects[projectId].milestones.length, "Invalid milestone index");
        require(!projects[projectId].completedMilestones[milestoneIndex], "Milestone already approved");

        projects[projectId].completedMilestones[milestoneIndex] = true;
        uint256 milestonePayment = projects[projectId].milestones[milestoneIndex];
        projects[projectId].escrowedAmount -= milestonePayment;

        payable(projects[projectId].freelancer).transfer(milestonePayment);

        emit MilestoneApproved(projectId, milestoneIndex);

        // Check if all milestones are complete
        bool allComplete = true;
        for (uint256 i = 0; i < projects[projectId].milestones.length; i++) {
            if (!projects[projectId].completedMilestones[i]) {
                allComplete = false;
                break;
            }
        }
        if (allComplete) {
            projects[projectId].projectComplete = true;
        }
    }

    // Function to create a dispute for a milestone
    function disputeMilestone(uint256 projectId, uint256 milestoneIndex) public onlyClient(projectId) {
        require(milestoneIndex < projects[projectId].milestones.length, "Invalid milestone index");

        disputes[disputeCount].projectId = projectId;
        disputes[disputeCount].milestoneIndex = milestoneIndex;
        disputes[disputeCount].votesForCompletion = 0;
        disputes[disputeCount].votesAgainstCompletion = 0;
        disputes[disputeCount].resolved = false;

        emit DisputeCreated(disputeCount, projectId, milestoneIndex);
        disputeCount++;
    }

    // Function for community members to vote on a dispute
    function voteOnDispute(uint256 disputeId, bool voteForCompletion) public returns (bool) {
        Dispute storage dispute = disputes[disputeId];
        require(!dispute.resolved, "Dispute already resolved");
        require(!dispute.hasVoted[msg.sender], "You have already voted");

        dispute.voters.push(msg.sender);
        dispute.hasVoted[msg.sender] = true;

        if (voteForCompletion) {
            dispute.votesForCompletion++;
        } else {
            dispute.votesAgainstCompletion++;
        }

        // Check if dispute can be resolved
        if (dispute.voters.length >= 3) { // Example: Resolve after 3 votes
            dispute.resolved = true;
            bool milestoneApproved = dispute.votesForCompletion > dispute.votesAgainstCompletion;
            emit DisputeResolved(disputeId, milestoneApproved);
            return milestoneApproved;
        }

        return false;
    }

    // Function to finalize the project
    function finalizeProject(uint256 projectId) public view onlyClient(projectId) returns (bool) {
        require(projects[projectId].projectComplete, "Project is not complete");
        return true;
    }

    // Function to get project details
    function getProjectDetails(uint256 projectId)
        public
        view
        returns (
            address freelancer,
            uint256[] memory milestones,
            bool[] memory completedMilestones,
            bool projectComplete
        )
    {
        Project storage project = projects[projectId];
        return (
            project.freelancer,
            project.milestones,
            project.completedMilestones,
            project.projectComplete
        );
    }
}