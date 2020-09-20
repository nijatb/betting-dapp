/* calculates odds for a certain bet */
export function calculateOdds(stake1, stake2) {
	// console.log(stake1);
	// console.log(stake2);

	let ratio = stake1 / stake2;

	if(stake2 === 0) {
		return `Cannot divide by 0`;
	}

	if (ratio < 1) {
		ratio = 1 / ratio;
	}

	if (Math.abs(ratio.toFixed(2) - ratio.toFixed(0)) < 0.001) {
		ratio = ratio.toFixed(0);
	} else {
		ratio = ratio.toFixed(2);
	}
	
	return `1 / ${ratio}`;
}