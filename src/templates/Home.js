import React from 'react';
import { Link } from 'react-router-dom';

export const Home = () => (
    <div>
        {/* Banner */}
        <section id="banner">
            <div className="inner">
                <div className="logo"><span className="icon fa-diamond"></span></div>
                <h2>TrustBet</h2>
                <p>The Home of Trusted, Decentralised Sports Betting</p>
                <ul className="actions vertical">
                    <li>
                        <Link to="/make" className="button special">Place a Bet</Link>
                    </li>
                </ul>
            </div>
        </section >

        {/* Wrapper */}
        <section id="wrapper">
            {/* One */}
            <section id="one" className="wrapper spotlight style1">
                <div className="inner">
                    <a className="image"><img src="images/free.jpg" alt="" /></a>
                    <div className="content">
                        <h2 className="major">No Middle Man, No Fees</h2>
                        <p>Using the Ethereum Blockchain, our site facilitates peer-to-peer betting using automated smart contracts meaning there is no middle man and absolutely zero fees for users.</p>
                    </div>
                </div>
            </section>

            {/* Two */}
            <section id="two" className="wrapper alt spotlight style2">
                <div className="inner">
                    <a className="image"><img src="images/football.jpg" alt="" /></a>
                    <div className="content">
                        <h2 className="major">Complete Trust in Our Data</h2>
                        <p>Developed by a team of researchers at ETH Zurich, <a href="https://tls-n.org/" target="_blank">TLS-N</a> allows our smart contracts to verify the source of data. This means that all outcomes of the matches you bet on are 100% authenticated and verified.</p>
                    </div>
                </div>
            </section>

            {/* Three */}
            <section id="three" className="wrapper spotlight style3">
                <div className="inner">
                    <a className="image"><img src="images/code.jpg" alt="" /></a>
                    <div className="content">
                        <h2 className="major">100% Transparent Service</h2>
                        <p>All of our smart contract code can be verified in our <a href="https://gitlab.doc.ic.ac.uk/tls-n-examples/BettingDapp" target="_blank">GitLab</a> repository meaning that you can verify everything we claim. Our smart contracts have been deployed on the Rinkeby test network at contract address <a href="https://rinkeby.etherscan.io/address/0xf2Ef82c979b671a613b560f34757283FCFDaC89d" target="_blank">0xf2Ef82c979b671a613b560f34757283FCFDaC89d</a>.</p>
                    </div>
                </div>
            </section>

            {/* Four */}
            <section id="four" className="wrapper alt style1">
                <div className="inner">
                    <h2 className="major">The Team</h2>
                    <p>This test product has been developed by a team of students at Imperial College London in order to demonstrate a real-world application of the TLS-N protocol.
                                        It is part of a series of decentralised applications with the others covering Insurance and Lending.</p>

                    <section className="features">
                        <article>
                            <a className="image"></a>
                            <h3 className="major">Matthew Morrison</h3>
                            <p>Responsible for smart contract and front-end development.
                                <span> </span>  
                                <a href="https://github.com/matthewsmorrison" target="_blank">GitHub</a>
                            </p>
                        </article>

                        <article>
                            <a href="#" className="image"></a>
                            <h3 className="major">Bastien Moyroud</h3>
                            <p>Responsible for front-end and server-side development.
                                <span> </span>  
                                <a href="https://github.com/bmoyroud" target="_blank">GitHub</a>
                            </p>
                        </article>

                        <article>
                            <a href="#" className="image"></a>
                            <h3 className="major">Mohammed Hussan</h3>
                            <p>Responsible for smart contract and front-end development.
                                <span> </span>  
                                <a href="https://github.com/Mo-Hussain" target="_blank">GitHub</a>
                            </p>
                        </article>

                        <article>
                            <a href="#" className="image"></a>
                            <h3 className="major">Vincent Groff</h3>
                            <p>Responsible for smart contract and front-end development.
                                <span> </span>  
                                <a href="https://github.com/vgroff" target="_blank">GitHub</a>
                            </p>
                        </article>

                        <article>
                            <a href="#" className="image"></a>
                            <h3 className="major">Mike Scott</h3>
                            <p>Responsible for server-side development.
                                <span> </span>  
                                <a href="https://github.com/bmwwilliams1" target="_blank">GitHub</a>
                            </p>
                        </article>

                        <article>
                            <a href="#" className="image"></a>
                            <h3 className="major">Nijat Bakhshaliyev</h3>
                            <p>Responsible for front-end development.
                                <span> </span>  
                                <a href="https://github.com/nijatb" target="_blank">GitHub</a>
                            </p>
                        </article>
                    </section>
                </div>
            </section>
        </section>
    </div>
);