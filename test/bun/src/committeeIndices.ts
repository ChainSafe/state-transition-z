import { binding } from "./binding.js";

// this is to sync the constant from zig to Bun which is 0xffffffff
const ERROR_INDEX = binding.getErrorIndex();

/** Pre-electra, byte count for random value is 1, post-electra, byte count for random value is 2 */
export declare enum ByteCount {
	One = 1,
	Two = 2,
}

export function computeProposerIndex(
	seed: Uint8Array,
	activeIndices: Uint32Array,
	effectiveBalanceIncrements: Uint16Array,
	randByteCount: ByteCount,
	maxEffectiveBalanceElectra: number,
	effectiveBalanceIncrement: number,
	rounds: number,
): number {
	const result = binding.computeProposerIndex(
		seed,
		seed.length,
		activeIndices,
		activeIndices.length,
		effectiveBalanceIncrements,
		effectiveBalanceIncrements.length,
		randByteCount,
		maxEffectiveBalanceElectra,
		effectiveBalanceIncrement,
		rounds,
	);
	if (result === ERROR_INDEX) {
		throw new Error("Failed to compute proposer index");
	}
	return result;
}

export function computeProposerIndexElectra(
	seed: Uint8Array,
	activeIndices: Uint32Array,
	effectiveBalanceIncrements: Uint16Array,
	maxEffectiveBalanceElectra: number,
	effectiveBalanceIncrement: number,
	rounds: number,
): number {
	const result = binding.computeProposerIndexElectra(
		seed,
		seed.length,
		activeIndices,
		activeIndices.length,
		effectiveBalanceIncrements,
		effectiveBalanceIncrements.length,
		maxEffectiveBalanceElectra,
		effectiveBalanceIncrement,
		rounds,
	);
	if (result === ERROR_INDEX) {
		throw new Error("Failed to compute proposer index");
	}
	return result;
}

export function computeSyncCommitteeIndices(
	seed: Uint8Array,
	activeIndices: Uint32Array,
	effectiveBalanceIncrements: Uint16Array,
	randByteCount: ByteCount,
	syncCommitteeSize: number,
	maxEffectiveBalanceElectra: number,
	effectiveBalanceIncrement: number,
	rounds: number,
): Uint32Array {
	const out = new Uint32Array(syncCommitteeSize);
	const result = binding.computeSyncCommitteeIndices(
		seed,
		seed.length,
		activeIndices,
		activeIndices.length,
		effectiveBalanceIncrements,
		effectiveBalanceIncrements.length,
		randByteCount,
		maxEffectiveBalanceElectra,
		effectiveBalanceIncrement,
		rounds,
		out,
		out.length,
	);
	if (result !== 0) {
		throw new Error(
			`Failed to compute sync committee indices, result = ${result}`,
		);
	}
	return out;
}

export function computeSyncCommitteeIndicesElectra(
	seed: Uint8Array,
	activeIndices: Uint32Array,
	effectiveBalanceIncrements: Uint16Array,
	syncCommitteeSize: number,
	maxEffectiveBalanceElectra: number,
	effectiveBalanceIncrement: number,
	rounds: number,
): Uint32Array {
	const out = new Uint32Array(syncCommitteeSize);
	const result = binding.computeSyncCommitteeIndicesElectra(
		seed,
		seed.length,
		activeIndices,
		activeIndices.length,
		effectiveBalanceIncrements,
		effectiveBalanceIncrements.length,
		maxEffectiveBalanceElectra,
		effectiveBalanceIncrement,
		rounds,
		out,
		out.length,
	);
	if (result !== 0) {
		throw new Error(
			`Failed to compute sync committee indices electra, result = ${result}`,
		);
	}
	return out;
}
