const contract = require('truffle-contract');

import Web3 from 'web3';
import FootballBettingAbi from '../../build/contracts/FootballBetting.json';
import { convertBet } from './bet'; 

export function getWeb3() {
    return new Promise((resolve, reject) => {
        // Wait for loading completion to avoid race conditions with web3 injection timing.)
        if (typeof window !== 'undefined') {
            window.addEventListener('load', function () {
                let web3 = window.web3;

                // checking if Web3 has been injected by the browser (Mist/MetaMask)
                console.log('Checking if MetaMask or Mist has injected Web3.')
                if (typeof web3 !== 'undefined') {
                    // use Mist/MetaMask's provider
                    web3 = new Web3(web3.currentProvider);

                    console.log('Web3 detected.');
                    resolve(web3);
                } else {
                    reject('Web3 not injected.');
                }
            })
        }
    });
};

// get contract from the blockchain so web3 can communicate with it
export async function getContractInstance(provider) {
    if (!provider) {
        console.log('Valid Web3 provider needed.');
        return;
    }

    console.log('Getting contract.');
    let bettingContract = contract(FootballBettingAbi);
    bettingContract.setProvider(provider);

    console.log('Getting contract instance.');
    let bettingContractInstance = await bettingContract.deployed();

    return bettingContractInstance;
};

export async function getAccounts(web3) {
    return new Promise((resolve, reject) => {
        if (!web3) {
            reject('Web3 Accounts undefined - is user logged in via Metamask?');
        }
        resolve(web3.eth.accounts);
    });
};

// get all existing bets from the blockchain and sort them into the corresponding lists
export async function getAllBets(contractInstance, _web3, currentAccount) {
    console.log('Getting all bets');

    console.log(contractInstance);
    console.log(_web3);
    console.log(currentAccount);

    let web3 = _web3;

    // arrays to be returned
    let nonUserBets = [], userBets = [], userAcceptedBets = [];

    // get all bet ids
    let betIds = await contractInstance.getBets();

    for (let i = 0; i < betIds.length; i++) {
        // get the bet corresponding to the id
        let bet = await contractInstance.bets(betIds[i])//.getBet(id)
        console.log(bet);

        // convert the array into the corresponding bet object

        // TODO: check why web3 returns undefined?
        console.log('Web3');
        console.log(web3);

        // web3 = await getWeb3();
        // console.log(web3);

        bet = await convertBet(bet, web3);
        
        // if the bet not been deleted
        if (!bet.deleted) {
            // and not yet accepted
            if (!bet.accepted) {
                // and if the user proposed the bet, add it to user bets
                if (bet.belongsTo === currentAccount) {
                    userBets.push(bet);
                } else {
                    //  if another user proposed it, add to list of claimable bets
                    nonUserBets.push(bet);
                }
            } else if (currentAccount === bet.belongsTo || currentAccount === bet.acceptedBy) {
                // if bet accepted and user involved, add it to acccepted bets list
                userAcceptedBets.push(bet);
            }
        }
    }

    return { userAcceptedBets: userAcceptedBets, userBets: userBets, nonUserBets: nonUserBets };

    // this.setState({ userAcceptedBets: userAcceptedBets, userBets: userBets, nonUserBets: nonUserBets })
}

