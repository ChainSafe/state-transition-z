import { describe, expect, it } from "bun:test";
import { shuffleList, unshuffleList } from "../../src/shuffle.js";

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

	for (const [i, { input, expected }] of testCases.entries()) {
		it(`should unshuffle ${i}`, () => {
			const shuffled = input.slice();
			const seed = new Uint8Array(32).fill(0);
			const rounds = 32;
			const result = unshuffleList(shuffled, seed, rounds);
			expect(result).toEqual(expected);
			const result2 = shuffleList(result, seed, rounds);
			expect(result2).toEqual(input);
		});
	}
});
