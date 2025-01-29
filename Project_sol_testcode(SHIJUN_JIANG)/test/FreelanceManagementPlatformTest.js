const FreelanceManagementPlatform = artifacts.require("FreelanceManagementPlatform");
const { expectRevert } = require("@openzeppelin/test-helpers");

contract("FreelanceManagementPlatform", (accounts) => {
    const [client, freelancer, voter1, voter2, voter3] = accounts;
    const milestonePayments = [web3.utils.toWei("1", "ether"), web3.utils.toWei("2", "ether")];
    const descriptions = ["Milestone 1", "Milestone 2"];

    let platform;

    beforeEach(async () => {
        platform = await FreelanceManagementPlatform.new();
    });

    it("should create a project successfully", async () => {
        await platform.createProject(freelancer, milestonePayments, descriptions, {
            from: client,
            value: web3.utils.toWei("3", "ether"),
        });

        const projectDetails = await platform.getProjectDetails(0);

        assert.equal(projectDetails.freelancer, freelancer);
        assert.deepEqual(
            projectDetails.milestones.map((m) => m.toString()),
            milestonePayments.map((m) => m.toString())
        );
        assert.equal(projectDetails.projectComplete, false);
    });

    it("should allow freelancer to submit a milestone", async () => {
        await platform.createProject(freelancer, milestonePayments, descriptions, {
            from: client,
            value: web3.utils.toWei("3", "ether"),
        });

        await platform.submitMilestone(0, 0, { from: freelancer });

        // No assertion since it's an event-driven function, will assert using other tests.
    });

    it("should allow client to approve milestone and release payment", async () => {
        await platform.createProject(freelancer, milestonePayments, descriptions, {
            from: client,
            value: web3.utils.toWei("3", "ether"),
        });

        await platform.submitMilestone(0, 0, { from: freelancer });

        const initialBalance = web3.utils.toBN(await web3.eth.getBalance(freelancer));
        await platform.approveMilestone(0, 0, { from: client });

        const finalBalance = web3.utils.toBN(await web3.eth.getBalance(freelancer));
        const milestonePayment = web3.utils.toBN(milestonePayments[0]);

        assert(finalBalance.sub(initialBalance).eq(milestonePayment), "Freelancer should receive payment");
    });

    it("should handle disputes and resolve by voting", async () => {
        await platform.createProject(freelancer, milestonePayments, descriptions, {
            from: client,
            value: web3.utils.toWei("3", "ether"),
        });

        await platform.submitMilestone(0, 0, { from: freelancer });
        await platform.disputeMilestone(0, 0, { from: client });

        await platform.voteOnDispute(0, true, { from: voter1 }); // Vote for completion
        await platform.voteOnDispute(0, false, { from: voter2 }); // Vote against completion
        await platform.voteOnDispute(0, true, { from: voter3 }); // Vote for completion

        const dispute = await platform.disputes(0);

        assert.equal(dispute.resolved, true, "Dispute should be resolved");
        assert.equal(dispute.votesForCompletion.toString(), "2", "Votes for completion should be 2");
        assert.equal(dispute.votesAgainstCompletion.toString(), "1", "Votes against completion should be 1");
    });

    it("should get project details correctly", async () => {
        await platform.createProject(freelancer, milestonePayments, descriptions, {
            from: client,
            value: web3.utils.toWei("3", "ether"),
        });

        const projectDetails = await platform.getProjectDetails(0);

        assert.equal(projectDetails.freelancer, freelancer);
        assert.deepEqual(
            projectDetails.milestones.map((m) => m.toString()),
            milestonePayments.map((m) => m.toString())
        );
        assert.deepEqual(
            projectDetails.completedMilestones.map((m) => m.toString()),
            ["false", "false"]
        );
        assert.equal(projectDetails.projectComplete, false);
    });
});