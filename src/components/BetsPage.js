import React from 'react';

import { BetList } from './BetList';

import { CLAIM_BET } from '../utils/actions';

export class BetsPage extends React.Component {
    render() {
        return (
            <section id="wrapper">
                <header>
                    <div className="inner">
                        <h2>Your Bets</h2>

                        <a href="#outstanding" className="button special">Filled Bets</a>
                        <a href="#historical" className="button special">Unfilled Bets</a>
                    </div>
                </header>

                {/* Content */}
                <div className="wrapper">
                    <div className="inner">
                        <section id="outstanding">
                            <h3 className="major">Your Filled Bets</h3>
                            <p>All the bets that you have placed that have been taken up by other users.</p>

                            <BetList bets={this.props.unfilled_bets} action={CLAIM_BET} />

                        </section>
                    </div>
                </div>
            </section>
        );
    }
}