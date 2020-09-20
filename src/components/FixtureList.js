import React from 'react';

import { FixtureListItem } from './FixtureListItem';

import { getFixtures } from '../utils/api';


// React component for getting a list of fixtures and letting the user select one
export class FixtureList extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            error: null,
            isLoaded: false
        };
    }

    // Called when component mounts, fetchs the games in next 40 days
    componentDidMount() {
        console.log('LOADING');

        getFixtures()
            .then(results => {
                return results.json();
            })
            .then(
                data => {
                    console.log(data);

                    // only show games that have a home and away team
                    let fixtures = data.fixtures.filter(fixture => fixture.status === "TIMED");

                    console.log(fixtures);

                    // save the fixture list
                    this.setState({
                        isLoaded: true,
                        fixtures: fixtures
                    });
                    console.log(this.state);
                }
            )
    }

    // Displays a list of upcoming matches
    render() {
        let that = this;

        if (!this.state.isLoaded) {
            return (
                <div> Loading... </div>
            );
        } else {
            return (
                <div className="table-wrapper">
                    <table>
                        <thead>
                            <tr>
                                <th>Teams</th>
                                <th>Date</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {this.state.fixtures.map(function (fixture) {
                                return <FixtureListItem key={fixture.id} fixture={fixture} id={fixture.id} updateSelectedFixture={that.props.updateSelectedFixture} />
                            })}
                        </tbody>
                    </table>
                </div>
            );
        }
    }
}