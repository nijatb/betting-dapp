import React from 'react';

import { FixtureList } from './FixtureList';
import { BetCreator } from './BetCreator';

export class FixturesPage extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            fixture: {}
        };

        this.updateSelectedFixture = this.updateSelectedFixture.bind(this);
    }

    updateSelectedFixture(fixture) {
        console.log(fixture);
        this.setState({
            fixture: fixture
        }, function () {
            console.log(this.state);
        });
    }

    render() {
        return (
            <div>
                <section id="wrapper">
                    <header>
                        <div className="inner">
                            <h2>Make a Bet</h2>
                        </div>
                    </header>

                    {/* Content */}
                    <div className="wrapper">
                        <div className="inner">
                            <h3 className="major">How To Make a Bet</h3>
                            <p>On this page you will be able to see a selection of upcoming sports matches that you can bet on.
									Simple click 'select fixture', fill in the parameters, and then your bet will have been placed.</p>

                            <h3 className="major">Upcoming Sports Matches</h3>

                            <FixtureList updateSelectedFixture={this.updateSelectedFixture}/>
                        </div>
                    </div>
                </section>

                <BetCreator ethereum={this.props.ethereum} fixture={this.state.fixture} />
            </div>
        );
    }
}