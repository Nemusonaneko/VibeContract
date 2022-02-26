const { ethers, GasTracker } = require("hardhat");
const { expect } = require("chai");

describe("VibeDeposit", function () {
    before(async function () {
        this.signers = await ethers.getSigners();
        this.Token = await ethers.getContractFactory("Dai");
        this.Vibe = await ethers.getContractFactory("VibeDeposit");
        this.owner = this.signers[0];
        this.alice = this.signers[1];
        this.bob = this.signers[2];
    });

    this.beforeEach(async function () {
        const chainId = await ethers.provider.network.chainId
        this.token = await this.Token.deploy(chainId);
        this.vibe = new GasTracker(await this.Vibe.deploy(this.token.address), {
            logAfterTx: true
        });
        this.token.mint(this.alice.address, "1000");
        this.token.mint(this.bob.address, "1000");
        await this.token.connect(this.alice).approve(this.vibe.address, "500");
        await this.token.connect(this.bob).approve(this.vibe.address, "500");
    });

    it("Deposit token = token passed through constructor", async function () {
        expect(await this.vibe.tokenToDeposit()).to.eq(await this.token.address);
    });

    it("Deposit works", async function () {
        await this.vibe.connect(this.alice).deposit("500");
        expect(await this.token.balanceOf(this.alice.address)).to.equal("500");
        expect(await this.vibe.getDepositorBalance(this.alice.address)).to.equal("500");
    });

    it("Becoming receiver works", async function () {
        await this.vibe.connect(this.alice).becomeReceiver()
        expect((await this.vibe.getReceiverInfo(this.alice.address))[0]).to.equal("0");
        expect((await this.vibe.getReceiverInfo(this.alice.address))[1]).to.equal(true);
    });

    it("Can transfer to receiver", async function () {
        await this.vibe.connect(this.alice).deposit("500");
        await this.vibe.connect(this.bob).becomeReceiver();
        await this.vibe.connect(this.alice).transferToReceiver(this.bob.address, "10");
        expect(await this.vibe.getDepositorBalance(this.alice.address)).to.equal("490");
        expect((await this.vibe.getReceiverInfo(this.bob.address))[0]).to.equal("10");
    });

    it("Withdrawing works", async function () {
        await this.vibe.connect(this.alice).deposit("500");
        await this.vibe.connect(this.bob).becomeReceiver();
        await this.vibe.connect(this.alice).transferToReceiver(this.bob.address, "300");
        await this.vibe.connect(this.bob).withdraw("300");
        expect((await this.vibe.getReceiverInfo(this.bob.address))[0]).to.equal("0");
    });

    it("Cannot deposit more than approved", async function () {
        await expect(this.vibe.connect(this.alice).deposit("600")).to.be.revertedWith("STF");
    })

    it("Cannot deposit more than they have", async function () {
        await this.token.connect(this.alice).approve(this.vibe.address, "5000");
        await expect(this.vibe.connect(this.alice).deposit("1200")).to.be.revertedWith("STF");
    });

    it("Cannot withdraw when not receiver()", async function () {
        await expect(this.vibe.connect(this.alice).withdraw("100")).to.be.revertedWith("NotAReceiver()");
    });

    it("Connect withdraw more than balance stored", async function () {
        await this.vibe.connect(this.alice).deposit("500");
        await this.vibe.connect(this.bob).becomeReceiver();
        await this.vibe.connect(this.alice).transferToReceiver(this.bob.address, "300");
        await expect(this.vibe.connect(this.bob).withdraw("1000")).to.be.revertedWith("AmountWithdrawnHigherThanExistingBalance()");
    })

    it("Cannot be a receiver when existing receiver", async function () {
        await this.vibe.connect(this.bob).becomeReceiver();
        await expect(this.vibe.connect(this.bob).becomeReceiver()).to.be.revertedWith("AlreadyAReceiver()");
    })

    it("Cannot transfer to nonexisting receiver", async function () {
        await this.vibe.connect(this.alice).deposit("500");
        await expect(this.vibe.connect(this.alice).transferToReceiver(this.bob.address, "300")).to.be.revertedWith("ReceiverDoesNotExist()");
    })

    it("Cannot transfer amount higher than balance in deposit", async function () {
        await this.vibe.connect(this.alice).deposit("500");
        await this.vibe.connect(this.bob).becomeReceiver();
        await expect(this.vibe.connect(this.alice).transferToReceiver(this.bob.address, "800")).to.be.revertedWith("TransferAmountHigherThanBalance()");
    })
})