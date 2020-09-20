require('isomorphic-fetch');
import expectThrow from '../helpers/expectThrow';

var Betting = artifacts.require("Betting");

contract('Betting', async function(accounts, app) {

  it("A user should be able to propose a bet, which can be retrieved", async function() {
    var app;
    var proposer = accounts[0];
    var proposerAmount = web3.toWei(1, "ether");
    var acceptorAmount = web3.toWei(1, "ether");
    var totalAmount = web3.toWei(2, "ether");
    var homeScore = 1;
    var awayScore = 0;
    var fixtureID = 158946;
    var football = {};
    football.authToken = '90e2c71e05cd488ba53f9327fc3f7db0';

    var url = 'https://tlsproof.bastien.tech/proofgen.py?proof_type=2&url=http://api.football-data.org/v1/fixtures/' + fixtureID + '?head2head=0'
    console.log("url ", url)
    // var myHeaders = new Headers({
    //   'X-Auth-Token': football.authToken
    // })
    var fetchData = {
      method: 'GET',
      // headers: myHeaders,
    };
    var myReq = new Request(url, fetchData)
    var response = await fetch(myReq)
    console.log("response ", response.__proto__)
    var buf = await response.arrayBuffer()
    var proof = buf
    console.log("proof ", proof);

    return Betting.deployed().then(function(instance) {
      app = instance;
      let event = app.ParseString(function(error, result) {
        if (!error)
          console.log("proof in contract", result.args.word);
      })
      return app.proposeBet(proof, acceptorAmount, homeScore, awayScore, {from: proposer, value: proposerAmount});
    });
  });

});
