import { randomBytes } from "node:crypto";
import { bench, describe } from "@chainsafe/benchmark";
import {
	EFFECTIVE_BALANCE_INCREMENT,
	MAX_EFFECTIVE_BALANCE_ELECTRA,
	SHUFFLE_ROUND_COUNT,
	SYNC_COMMITTEE_SIZE,
} from "@lodestar/params";
import { computeSyncCommitteeIndicesElectra } from "../../src/index.js";
import { naiveComputeSyncCommitteeIndicesElectra } from "../referenceImplementation.js";

describe("computeIndices", () => {
	for (const listSize of [
		16384, 250_000,
		1_000_000,
		// Don't run 4_000_000 since it's very slow and not testnet has gotten there yet
		// 4e6,
	]) {
		// don't want to generate random seed to investigate performance
		// each seed may lead to different cached items hence different performance
		const seed = new Uint8Array(32).fill(1);
		const vc = listSize;
		const activeIndices = new Uint32Array(
			Array.from({ length: vc }, (_, i) => i),
		);
		const effectiveBalanceIncrements = new Uint16Array(vc);
		for (let i = 0; i < vc; i++) {
			effectiveBalanceIncrements[i] = 32 + 32 * (i % 64);
		}

		bench({
			id: `JS   - computeSyncCommitteeIndices - ${listSize} indices`,
			fn: () => {
				naiveComputeSyncCommitteeIndicesElectra(
					seed,
					activeIndices,
					effectiveBalanceIncrements,
				);
			},
		});

		bench({
			id: `Zig   - computeSyncCommitteeIndices - ${listSize} indices`,
			fn: () => {
				computeSyncCommitteeIndicesElectra(
					seed,
					activeIndices,
					effectiveBalanceIncrements,
					SYNC_COMMITTEE_SIZE,
					MAX_EFFECTIVE_BALANCE_ELECTRA,
					EFFECTIVE_BALANCE_INCREMENT,
					SHUFFLE_ROUND_COUNT,
				);
			},
		});
	}
});
