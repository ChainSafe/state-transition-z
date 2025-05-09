import { describe, expect, it, beforeAll } from "bun:test";
import { randomBytes } from "node:crypto";
import {
	EFFECTIVE_BALANCE_INCREMENT,
	ForkSeq,
	MAX_EFFECTIVE_BALANCE_ELECTRA,
	SHUFFLE_ROUND_COUNT,
	SYNC_COMMITTEE_SIZE,
} from "@lodestar/params";
import { computeProposerIndex } from "@lodestar/state-transition";

import {
	computeProposerIndexElectra,
	computeSyncCommitteeIndicesElectra,
  initBinding,
} from "../../src/index.js";
import { naiveComputeSyncCommitteeIndicesElectra } from "../referenceImplementation.js";

describe("computeProposerIndex", () => {
  beforeAll(async () => {
    await initBinding();
  });

	it("should compute the same index as reference implementation", async () => {
		const seed = randomBytes(32);
		const vc = 1000;
		const activeIndices = new Uint32Array(
			Array.from({ length: vc }, (_, i) => i),
		);
		const effectiveBalanceIncrements = new Uint16Array(vc);
		for (let i = 0; i < vc; i++) {
			effectiveBalanceIncrements[i] = 32 + 32 * (i % 64);
		}
		expect(
			computeProposerIndexElectra(
				seed,
				activeIndices,
				effectiveBalanceIncrements,
				MAX_EFFECTIVE_BALANCE_ELECTRA,
				EFFECTIVE_BALANCE_INCREMENT,
				SHUFFLE_ROUND_COUNT,
			),
		).toEqual(
			computeProposerIndex(
				ForkSeq.electra,
				effectiveBalanceIncrements,
				activeIndices,
				seed,
			),
		);
	});
});

describe("getNextSyncCommitteeIndices", () => {
	it("should compute the same index as reference implementation", async () => {
		const seed = randomBytes(32);
		const vc = 1000;
		const activeIndices = new Uint32Array(
			Array.from({ length: vc }, (_, i) => i),
		);
		const effectiveBalanceIncrements = new Uint16Array(vc);
		for (let i = 0; i < vc; i++) {
			effectiveBalanceIncrements[i] = 32 + 32 * (i % 64);
		}
		expect(
			new Array(
				...computeSyncCommitteeIndicesElectra(
					seed,
					activeIndices,
					effectiveBalanceIncrements,
					SYNC_COMMITTEE_SIZE,
					MAX_EFFECTIVE_BALANCE_ELECTRA,
					EFFECTIVE_BALANCE_INCREMENT,
					SHUFFLE_ROUND_COUNT,
				),
			),
		).toEqual(
			naiveComputeSyncCommitteeIndicesElectra(
				seed,
				activeIndices,
				effectiveBalanceIncrements,
			),
		);
	});
});
