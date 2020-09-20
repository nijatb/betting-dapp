import React from 'react';

import { calculateOdds as getOdds } from '../utils/calculateOdds';
import { getFixtureProof } from '../utils/api';

// TODO: move modal html and css to bet creator
import './Modal.css';

function closeModal() {
    // get the modal
    var modal = document.getElementById('myModal');

    if (modal) {
        // when user clicks on <span> (x), close the modal    
        modal.style.display = "none";
    } else {
        console.log('No modal found');
    }
}

// React component used for creating new bets
export class BetCreator extends React.Component {
    constructor(props) {
        super(props);

        // This binding is necessary to make `this` work in the callback
        this.addBet = this.addBet.bind(this);
        this.calculateOdds = getOdds.bind(this);

        this.state = {
            bet: {
                homeScore: 0,
                awayScore: 0,
                proposerStake: 0,
                accepterStake: 0
            }
        };
    }

    // add new bet
    async addBet(e) {
        e.preventDefault();
        console.log('About to add new bet to Rinkeby');
        
        let id = this.props.fixture.id;
        getFixtureProof(id)
            .then(proof => {
                // addNewBet(this.state.bet, proof);
                let bet = this.state.bet;

                // TODO: reformat the below in its own function
                // TODO: reformat the event listener and add to blockchain functions separately
                console.log('About to add new bet to Rinkeby');

                console.log(bet);
                console.log(proof);

                let ethereum = this.props.ethereum;
                console.log(ethereum);

                let response = ethereum.contractInstance.proposeBet(
                    proof,
                    ethereum.web3.toWei(bet.accepterStake, "ether"),
                    bet.homeScore,
                    bet.awayScore,
                    {
                        from: ethereum.currentAccount,
                        value: ethereum.web3.toWei(bet.proposerStake, "ether")
                    });
                closeModal();
                console.log("Add New Bet: " + response);
            });
    }

    updateState(evt) {
        console.log(evt.target);
        let target = evt.target;
        let id = target.id;

        let newState = this.state;
        // console.log(this.state);        

        switch (id) {
            case 'homeScore':
            case 'awayScore':
                newState.bet[id] = parseInt(target.value, 10);
                break;

            case 'proposerStake':
            case 'accepterStake':
                newState.bet[id] = parseFloat(target.value);
                break;

            default:
                console.log('Not updating any state.');

        }

        // update state
        this.setState(newState);
    }

    render() {
        return (
            <div id="myModal" className="modal">
                {/* Modal content */}
                <div className="modal-content" >
                    <span className="close1" onClick={closeModal}>&times;</span>
                    <div className="6u 12u$(xsmall)">
                    </div>

                    <ul className="alt">
                        {/* <h1> TEST: {JSON.stringify(this.props.fixture)} </h1> */}

                        <li>
                            <label htmlFor="demo-name">Fixture You Are Betting On: {this.props.fixture.homeTeamName} - {this.props.fixture.awayTeamName} </label>
                        </li>

                        {/* IDs are very important in the logic - not to be deleted! */}
                        <li>
                            <label htmlFor="demo-name">Predicted Home Score ({this.props.fixture.homeTeamName})</label>
                            <input type="number" id="homeScore" step="1" min="0" value={this.state.bet.homeScore} onChange={evt => this.updateState(evt)} />
                        </li>

                        <li>
                            <label htmlFor="demo-name">Predicted Away Score ({this.props.fixture.awayTeamName})</label>
                            <input type="number" id="awayScore" step="1" min="0" value={this.state.bet.awayScore} onChange={evt => this.updateState(evt)} />
                        </li>

                        <li>
                            <label htmlFor="demo-name">Your Stake (In Ether)</label>
                            <input type="number" id="proposerStake" min="0.01" step="0.01" value={this.state.bet.proposerStake} onChange={evt => this.updateState(evt)} />
                        </li>

                        <li>
                            <label htmlFor="demo-name">Your Rival's Stake (In Ether)</label>
                            <input type="number" id="accepterStake" min="0.01" step="0.01" value={this.state.bet.accepterStake} onChange={evt => this.updateState(evt)} />
                        </li>

                        <li>
                            <label htmlFor="demo-name">Your Calculated Odds: {this.calculateOdds(this.state.bet.proposerStake, this.state.bet.accepterStake)} </label>
                        </li>

                        <li onClick={this.addBet}><a className="button small special">Propose Bet</a></li>
                    </ul>
                </div >
            </div >
        );
    }
}