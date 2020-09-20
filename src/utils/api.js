let headers = new Headers({
	'X-Auth-Token': '90e2c71e05cd488ba53f9327fc3f7db0',
	'X-Response-Control': 'minified'
});

function getFixtureUrl(id) {
	return `https://api.football-data.org/v1/fixtures/${id}/?head2head=0`;
}

function getFixturesUrl(competition_id) {
	return `https://api.football-data.org/v1/competitions/${competition_id}/fixtures?timeFrame=n40`;
}

function getProofUrl(url) {
	return `https://api.tlsproof.bastien.tech?proof=true&url=${url}`;
}

// function getResponseAndProofUrl(url) {
// 	return `https://api.tlsproof.bastien.tech?response=true&proof=true&url=${url}`;
// }

function get(url, newHeaders) {
	return fetch(url, {
		method: 'GET',
		headers: newHeaders
	});
}

// TODO: sort out use of async and wait / when are they really needed?
// THIS TODO applies to the whole project

// fetch fixture from football API
export async function getFixture(id) {
	let url = getFixtureUrl(id);
	console.log(url);

	let results = await get(url, headers);

	return results.text();
};

function getJson(response) {
	return new Promise(resolve => {
		response.json().then(function (json) {
			console.log(json);
			resolve(json);
		});
	});
}

// fetch proof for a fixture from mirror server
export async function getFixtureProof(id) {
	let url = getFixtureUrl(id);
	let proofUrl = getProofUrl(url);

	console.log(proofUrl);
	let response = await get(proofUrl, headers);	
	let json = await getJson(response);

	return json.proof;
};

export async function getFixtures(competition_id) {
	// TODO: move competition_id
	competition_id = 467;

	let url = getFixturesUrl(competition_id);
	console.log(url);

	let results = await get(url, headers);

	return results;
};