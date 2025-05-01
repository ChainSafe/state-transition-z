import { describe, expect, it } from "bun:test";
import {
	shuffleList,
	unshuffleList,
	withPollingParams,
} from "../../src/shuffle.js";

describe("unshuffleList", () => {
	const testCases: { input: Uint32Array; expected: Uint32Array }[] = [
		// same test case to shuffle.zig
		{
			input: Uint32Array.from(Array.from({ length: 9 }, (_, i) => i)),
			expected: Uint32Array.from([6, 2, 3, 5, 1, 7, 8, 0, 4]),
		},
		// another test case
		{
			input: Uint32Array.from(Array.from({ length: 32 }, (_, i) => i)),
			expected: Uint32Array.from([
				20, 24, 29, 14, 7, 4, 30, 5, 17, 27, 12, 31, 28, 11, 22, 8, 15, 25, 18,
				0, 26, 19, 13, 10, 3, 21, 23, 9, 6, 16, 2, 1,
			]),
		},
	];

	const seed = new Uint8Array(32).fill(0);
	const rounds = 32;
	for (const [i, { input, expected }] of testCases.entries()) {
		it(`synced unshuffle then shuffle, test case ${i}`, () => {
			const shuffled = input.slice();
			const result = unshuffleList(shuffled, seed, rounds);
			expect(result).toEqual(expected);
			const result2 = shuffleList(result, seed, rounds);
			expect(result2).toEqual(input);
		});

		// start polling right after the call for every 1ms, throw error if after 100ms
		const { asyncShuffleList, asyncUnshuffleList } = withPollingParams(
			0,
			1,
			100,
		);

		const testWithNFactor = async (n: number) => {
			let promises: Promise<Uint32Array>[] = [];
			// call asyncUnshuffleList in parallel n times
			for (let j = 0; j < n; j++) {
				const shuffled = input.slice();
				promises.push(asyncUnshuffleList(shuffled, seed, rounds));
			}

			const results = await Promise.all(promises);
			for (const result of results) {
				expect(result).toEqual(expected);
			}

			promises = [];
			for (let j = 0; j < n; j++) {
				promises.push(asyncShuffleList(results[j], seed, rounds));
			}

			const results2 = await Promise.all(promises);
			for (const result of results2) {
				expect(result).toEqual(input);
			}
		};

		it(`async unshuffle then async shuffle, test case ${i}`, async () => {
			await testWithNFactor(1);
		});

		it(`async unshuffle then async shuffle, 4 in parallel, test case ${i}`, async () => {
			await testWithNFactor(4);
		});

		it(`async unshuffle then async shuffle, 4 in parallel, 10 times, test case ${i}`, async () => {
			for (let i = 0; i < 10; i++) {
				await testWithNFactor(4);
			}
		});

		// TODO: add negative unit test, do a lot in parallel and it fails
	}
});

// TODO: the same tests to @chainsafe/swap-or-not-shuffle
