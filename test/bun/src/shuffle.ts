import { binding } from "./binding.js";

/**
 * shuffle a list of indices in place
 * activeIndices is modified, we return it for convenience and make it the same to @chainsafe/swap-or-not-shuffle
 */
export function shuffleList(
	activeIndices: Uint32Array,
	seed: Uint8Array,
	rounds: number,
): Uint32Array {
	const result = binding.shuffleList(
		activeIndices,
		activeIndices.length,
		seed,
		seed.length,
		rounds,
	);

	if (result !== 0) {
		throw new Error(`Shuffle failed with error code: ${result}`);
	}

	return activeIndices;
}

/**
 * unshuffle a list of indices in place
 * activeIndices is modified, we return it for convenience and make it the same to @chainsafe/swap-or-not-shuffle
 */
export function unshuffleList(
	activeIndices: Uint32Array,
	seed: Uint8Array,
	rounds: number,
): Uint32Array {
	const result = binding.unShuffleList(
		activeIndices,
		activeIndices.length,
		seed,
		seed.length,
		rounds,
	);

	if (result !== 0) {
		throw new Error(`Unshuffle failed with error code: ${result}`);
	}

	return activeIndices;
}
