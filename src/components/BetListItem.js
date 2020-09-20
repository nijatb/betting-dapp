import React from 'react';

import { calculateOdds } from '../utils/calculateOdds';

export class BetListItem extends React.Component {
    render() {
        let bet = this.props.bet;
        let odds = calculateOdds(bet.proposerStake, bet.accepterStake);

        if (this.props.actionTxt === null) {
            // If there is no button text to show, just show the bet
            // TODO: remove code duplication
            return (
                <tr>
                    <td> {bet.fixtureDetails.homeTeamName} {bet.homeScore} - {bet.awayScore} {bet.fixtureDetails.awayTeamName} </td>
                    <td> {bet.proposerStake} - {bet.accepterStake} </td>
                    <td> {odds} </td>
                </tr>
            );
        } else {
            // Otherwise show both the bet text and the button
            return (
                <tr>
                    <td> {bet.fixtureDetails.homeTeamName} {bet.homeScore} - {bet.awayScore} {bet.fixtureDetails.awayTeamName} </td>
                    <td> {bet.proposerStake} - {bet.accepterStake} </td>
                    <td> {odds} </td>
                    <td><a className="button small" onClick={evt => this.props.action(evt, bet)}>{this.props.actionTxt}</a></td>
                </tr>
            );
        }
    }
}