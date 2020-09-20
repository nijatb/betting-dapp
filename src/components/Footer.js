import React from 'react';

import { BetList } from './BetList';

import { Switch, Route } from 'react-router-dom';

import { REMOVE_BET } from '../utils/actions';

export class Footer extends React.Component {
    render() {
        return (
            <Switch>
                {/* determine which footer to render based on path */}
                <Route exact path="/bets">
                    <section id="footer">
                        <div className="inner">
                            <section id="historical">
                                <h3 className="major">Your Unfilled Bets</h3>
                                <p>A list of all the bets you have made that have not been taken up by another user.</p>

                                <BetList bets={this.props.filled_bets} action={REMOVE_BET} />
                            </section>

                            <ul className="copyright">
                                <li>&copy; TrustBet. All rights reserved.</li>
                            </ul>
                        </div>
                    </section>
                </Route>

                <Route>
                    <section id="footer">
                        <div className="inner">
                            <ul className="copyright">
                                <li>&copy; TrustBet. All rights reserved.</li>
                            </ul>
                        </div>
                    </section>
                </Route>
            </Switch>
        );
    }
}