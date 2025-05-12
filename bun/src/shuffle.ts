import { getBinding } from "./binding.js";

/**
 * shuffle a list of indices in place
 * activeIndices is modified, we return it for convenience and make it the same to @chainsafe/swap-or-not-shuffle
 */
export function shuffleList(
	activeIndices: Uint32Array,
	seed: Uint8Array,
	rounds: number,
): Uint32Array {
	validateShufflingParams(activeIndices, seed, rounds);

	const binding = getBinding();
	const clonedActiveIndices = activeIndices.slice();
	const result = binding.shuffleList(
		clonedActiveIndices,
		clonedActiveIndices.length,
		seed,
		seed.length,
		rounds,
	);

	if (result !== 0) {
		throw new Error(`Shuffle failed with error code: ${result}`);
	}

	return clonedActiveIndices;
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
	validateShufflingParams(activeIndices, seed, rounds);
	const binding = getBinding();

	const clonedActiveIndices = activeIndices.slice();
	const result = binding.unshuffleList(
		clonedActiveIndices,
		clonedActiveIndices.length,
		seed,
		seed.length,
		rounds,
	);

	if (result !== 0) {
		throw new Error(`Unshuffle failed with error code: ${result}`);
	}

	return clonedActiveIndices;
}

// same value to ErrorCode.Pending at zig side
const POLL_STATUS_PENDING = 10;
// same value to ErrorCode.Success at zig side
const POLL_STATUS_SUCCESS = 0;

/**
 * As of Apr 2025, Zig C-ABI does not support callback so have to implement polling solution and come up with below parameters:
 * - timeToWaitMs: wait ms before polling
 * - pollEveryMs: poll native every pollEveryMs
 * - timeoutMs: if it never finishes after this time, throw error
 *
 * see https://github.com/ChainSafe/blst-bun/issues/13#issuecomment-2814425010
 */
export function withPollingParams(
	timeToWaitMs: number,
	pollEveryMs: number,
	timeoutMs: number,
) {
	if (timeToWaitMs < 0 || pollEveryMs <= 0 || timeoutMs <= 0) {
		throw new Error("Invalid parameter");
	}

	async function doShuffleList(
		activeIndices: Uint32Array,
		seed: Uint8Array,
		rounds: number,
		nativeShuffleFn: (
			activeIndices: Uint32Array,
			length: number,
			seed: Uint8Array,
			seedLength: number,
			rounds: number,
		) => number,
	): Promise<Uint32Array> {
		validateShufflingParams(activeIndices, seed, rounds);

		const start = Date.now();
		const clonedActiveIndices = activeIndices.slice();
		const pointerIdx = nativeShuffleFn(
			clonedActiveIndices,
			clonedActiveIndices.length,
			seed,
			seed.length,
			rounds,
		);
		if (timeToWaitMs > 0) {
			// sleep
			await new Promise((resolve) => setTimeout(resolve, timeToWaitMs));
		}

		return new Promise((resolve, reject) => {
			const binding = getBinding();
			const interval = setInterval(() => {
				if (Date.now() - start > timeoutMs) {
					clearInterval(interval);
					binding.releaseAsyncResult(pointerIdx);
					reject(new Error(`Timeout after ${timeoutMs}ms`));
					return;
				}

				const result = binding.pollAsyncResult(pointerIdx);
				switch (result) {
					case POLL_STATUS_SUCCESS:
						clearInterval(interval);
						binding.releaseAsyncResult(pointerIdx);
						resolve(clonedActiveIndices);
						return;
					case POLL_STATUS_PENDING:
						break;
					default:
						clearInterval(interval);
						binding.releaseAsyncResult(pointerIdx);
						reject(
							new Error(
								`Native shuffle function failed with error code: ${result}`,
							),
						);
				}
			}, pollEveryMs);
		});
	}

	return {
		asyncShuffleList: (
			activeIndices: Uint32Array,
			seed: Uint8Array,
			rounds: number,
		): Promise<Uint32Array> => {
			const binding = getBinding();
			return doShuffleList(
				activeIndices,
				seed,
				rounds,
				binding.asyncShuffleList,
			);
		},
		asyncUnshuffleList: (
			activeIndices: Uint32Array,
			seed: Uint8Array,
			rounds: number,
		): Promise<Uint32Array> => {
			const binding = getBinding();
			return doShuffleList(
				activeIndices,
				seed,
				rounds,
				binding.asyncUnshuffleList,
			);
		},
	};
}

export function validateShufflingParams(
	activeIndices: Uint32Array,
	seed: Uint8Array,
	rounds: number,
): void {
	if (activeIndices.length >= 0xffffffff) {
		throw new Error("ActiveIndices must fit in a u32");
	}
	if (seed.length !== 32) {
		throw new Error("Shuffling seed must be 32 bytes long");
	}
	if (rounds < 0 || rounds > 255) {
		throw new Error("Rounds must be between 0 and 255");
	}
}
