import React from 'react';

import { BetList } from './BetList';

export class BrowsePage extends React.Component {
    render() {
        return (
            <section id="wrapper" >
                <header>
                    <div className="inner">
                        <h2>Browse Bets</h2>
                    </div>
                </header>

                {/* Content */}
                <div className="wrapper">
                    <div className="inner">

                        <h3 className="major">Browse Through Other Users' Bets</h3>
                        <p>On this page you can see all other bets made by other users on our site.</p>

                        <BetList bets={this.props.bets} action={this.props.action} ethereum={this.props.ethereum} />
                    </div>
                </div>
            </section>
        );
    }
}