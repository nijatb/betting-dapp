import { getFixture } from './api';

/* a class which holds all required information for a generated bet */
export class Bet {
    constructor(id, proposerStake, accepterStake, belongsTo, acceptedBy, homeScore, awayScore, fixtureDetails) {
        this.id = id
        this.proposerStake = proposerStake
        this.accepterStake = accepterStake
        this.belongsTo = belongsTo
        this.acceptedBy = acceptedBy
        this.fixtureDetails = fixtureDetails
        this.homeScore = homeScore
        this.awayScore = awayScore
    }

    setId(id) { this.id = id }
    setProposerStake(proposerStake) { this.proposerStake = proposerStake }
    setAcceptorStake(accepterStake) { this.accepterStake = accepterStake }
}

// gets details of a fixture, either from the cache or if it isnt there by calling the API
async function getFixtureDetails(fixtureId) {
    // for (let i = 0; i < this.savedFixtures.length; i++) {
    //     if (this.savedFixtures[i].id === fixtureId) {
    //         return this.savedFixtures[i]
    //     }
    // }

    let newFixStr = await getFixture(fixtureId);
    let newFixture = JSON.parse(newFixStr)["fixture"];
    // this.savedFixtures.push(newFixture);

    return newFixture;
}

// convert bet array to bet object
export async function convertBet(betArr, web3) {
    let amount = web3.fromWei(betArr[5].toNumber(), "ether");
    let amount2 = web3.fromWei(betArr[4].toNumber(), "ether");

    let proposer = betArr[1];
    let acceptor = betArr[2];

    let accepted = betArr[3];
    let deleted = betArr[11];

    let homeScore = betArr[6].toNumber();
    let awayScore = betArr[7].toNumber();

    let fixtureId = betArr[9].toNumber();
    let fixtureDetails = await getFixtureDetails(fixtureId);

    let bet = new Bet(betArr[0], amount, amount2, proposer, acceptor, homeScore, awayScore, fixtureDetails);
    bet.deleted = deleted;
    bet.accepted = accepted;

    return bet;
};