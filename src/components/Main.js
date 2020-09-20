import React from 'react';

import { Switch, Route } from 'react-router-dom';

// import templates
import { Home } from '../templates/Home';
import { Faq } from '../templates/Faq';
import { _404 } from '../templates/Errors';

// import components
import { BrowsePage } from './BrowsePage';
import { FixturesPage } from './FixturesPage';
import { BetsPage } from './BetsPage';

import { ACCEPT_BET } from '../utils/actions';

export class Main extends React.Component {
    constructor(props) {
        super(props);

        this.state = this.props.bundle;
        console.log(this.state);
    }


    // Displays a list of upcoming matches
    render() {
        return (
            <Switch>
                <Route exact path="/" component={Home} />

                <Route path="/make">
                    <FixturesPage ethereum={this.state.ethereum} />
                </Route>

                <Route path="/browse">
                    <BrowsePage bets={this.state.bets.nonUserBets} action={ACCEPT_BET} ethereum={this.state.ethereum} />
                </Route>

                <Route path="/bets">
                    <BetsPage filled_bets={this.state.bets.userBets} unfilled_bets={this.state.bets.userAcceptedBets} ethereum={this.state.ethereum} />
                </Route>

                <Route path="/faqs" component={Faq} />

                {/* default route: page not found */}
                <Route component={_404} />
            </Switch>
        );
    }
}