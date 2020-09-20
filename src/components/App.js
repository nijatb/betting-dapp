import React from 'react';
import { Switch, Route } from 'react-router-dom';

import { getWeb3, getContractInstance, getAccounts, getAllBets } from '../utils/ethereum';
import { ACCEPT_BET } from '../utils/actions';

// import templates
import { Home } from '../templates/Home';
import { Faq } from '../templates/Faq';
import { _404 } from '../templates/Errors';
import { Header } from '../templates/Header';

// import components
import { BrowsePage } from './BrowsePage';
import { FixturesPage } from './FixturesPage';
import { BetsPage } from './BetsPage';
import { Footer } from './Footer';

export class App extends React.Component {
	constructor(props) {
		super(props);

		this.state = {
			ethereum: {
				web3: null,
				contractInstance: null,
				currentAccount: null
			},
			bets: {
				nonUserBets: [],
				userBets: [],
				userAcceptedBets: []
			}
		};
	}
	
	// runs once react component is mounted in order to connect to the blockchain
	componentDidMount() {
		// get network provider and web3 instance.
		// see utils/getWeb3 for more info.
		getWeb3()
			.then(web3 => {
				console.log(web3);

				let updatedState = this.state;
				updatedState.ethereum.web3 = web3;
				this.setState(updatedState);

				// get accounts
				console.log('Get Web3 accounts.');
				return getAccounts(this.state.ethereum.web3);
			})
			.then(accounts => {
				let currentAccount = accounts[0];

				let updatedState = this.state;
				updatedState.ethereum.currentAccount = currentAccount;
				this.setState(updatedState);

				// TODO: fix listening to event emitted when adding a transaction
				// start watching for bet changes
				// var getBets = function () {
				// 	console.log("bet change event triggered");
				// 	this.getAllBets();
				// }.bind(this);
				// this.event = this.bettingContractInst.BetChange();
				// return this.event.watch(getBets);				

				// instantiate contract once web3 provided.
				return getContractInstance(this.state.ethereum.web3.currentProvider);
			})
			.then(contractInstance => {
				console.log(contractInstance);

				let updatedState = this.state;
				updatedState.ethereum.contractInstance = contractInstance;
				this.setState(updatedState);

				// TODO: have a closer look at the below and make sure to remove function when component unmounts
				// // create a function that regularly checks for changes to account
				// let checkChangeAccount = function (currentAccount, web3) {
				// 	if (currentAccount !== getAccounts(web3)[0]) {
				// 		currentAccount = getAccounts(web3)[0];

				// 		// get updated list of bets when changing user
				// 		getAllBets(contractInstance);
				// 	}
				// };

				// setInterval(checkChangeAccount(this.state.ethereum.currentAccount, this.state.ethereum.web3), 100);

				console.log(this.state);
				return getAllBets(contractInstance, this.state.ethereum.web3, this.state.ethereum.currentAccount);
			})
			.then(bets => {
				console.log(bets);

				let updatedState = this.state;
				updatedState.bets = bets;
				this.setState(updatedState);
				console.log(this.state)
			})
			.catch(err => {
				console.log(err);
			})
	}

	render() {
		return (
			<div>
				<Header />

				{/* TODO: refactor below in Main component */}
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

				<Footer filled_bets={this.state.bets.userBets} />
			</div>
		);
	}
}

// TODO: is this needed?
//export default App