import React from 'react';
import { Link } from 'react-router-dom';

export const Header = () => (
    <div>
        {/* Header */}
        <header id="header" className="alt">
            <h1>
                <Link to="/">TrustBet</Link>
            </h1>
            <nav>
                <a href="#menu">Menu</a>
            </nav>
        </header>

        {/* Menu */}
        <nav id="menu">
            <div className="inner">
                <h2>Menu</h2>

                <ul className="links">
                    <li>
                        <Link to="/">Home</Link>
                    </li>
                    <li>
                        <Link to="/make">Make A Bet</Link>
                    </li>
                    <li>
                        <Link to="/browse">Browse Bets</Link>
                    </li>
                    <li>
                        <Link to="/bets">Your Bets</Link>
                    </li>
                    <li>
                        <Link to="/faqs">FAQs</Link>
                    </li>
                </ul>
                <Link to="#" className="close">Close</Link>
            </div>
        </nav>
    </div>
);

