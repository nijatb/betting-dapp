import React from 'react';

import { getFixtureProof } from '../utils/api';
import { REMOVE_BET, ACCEPT_BET, CLAIM_BET } from '../utils/actions';

import { BetListItem } from './BetListItem';

export class BetList extends React.Component {
    render() {
        let actionCode = this.props.action;
        let action, actionTxt;

        let bets = this.props.bets;
        let ethereum = this.props.ethereum;

        switch (actionCode) {
            case REMOVE_BET:
                actionTxt = 'Remove Bet';
                action = async function (event, bet) {
                    event.preventDefault();
                    console.log('Remove Bet');

                    // TODO: check if below works
                    await ethereum.contractInstance.cancelBet(bet.id.toNumber(), { from: ethereum.currentAccount });
                };
                break;
                
            case ACCEPT_BET:
                actionTxt = 'Accept Bet';

                // accept at a given stake
                action = async function (event, bet) {
                    event.preventDefault();
                    console.log('Accept Bet');

                    // TODO: check if below works
                    await ethereum.contractInstance.acceptBet(bet.id.toNumber(), {
                        from: ethereum.currentAccount,
                        value: ethereum.web3.toWei(bet.accepterStake, "ether")
                    });
                };
                break;

            case CLAIM_BET:
                actionTxt = 'Claim Bet';

                // resolve bet on match completion
                action = async function (event, bet) {
                    event.preventDefault();
                    console.log('Claim Bet');

                    // TODO: check if below works
                    console.log(bet.fixtureDetails);
                    var proof = await getFixtureProof(bet.fixtureDetails.id);
                    console.log(proof);
                    await ethereum.contractInstance.resolveBet(bet.id.toNumber(), proof, { from: ethereum.currentAccount });
                };
                break;

            default:
                actionTxt = '';
                action = function (event) {
                    console.log('No action defined');
                }
        }

        if (bets.length > 0) {
            // If there are some bets to display, build 3 headers and map the bets
            // to BetView objects, passing in the widths
            return (
                <div className="table-wrapper">
                    <table>
                        <thead>
                            <tr>
                                <th>Predicted Result</th>
                                <th>Stakes (For-Against)</th>
                                <th>Odds (For)</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {bets.map(function (bet) {
                                return <BetListItem key={bet.id} bet={bet} action={action} actionTxt={actionTxt} />
                            })}
                        </tbody>
                    </table>
                </div>
            );
        }
        else {
            // If there are no bets to display, give a message saying so
            return (
                <div>
                    <h2>No bets to display</h2>
                </div>)
        }
    }
}