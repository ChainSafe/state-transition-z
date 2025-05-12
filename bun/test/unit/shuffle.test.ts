import { beforeAll, describe, expect, it } from "bun:test";
import { randomBytes } from "node:crypto";
import {
	initBinding,
	shuffleList,
	unshuffleList,
	withPollingParams,
} from "../../src/index.js";
import * as referenceImplementation from "../referenceImplementation.js";

// start polling right after the call for every 1ms, throw error if after 100ms
const { asyncShuffleList, asyncUnshuffleList } = withPollingParams(0, 1, 100);

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

	beforeAll(async () => {
		await initBinding();
	});

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

// the same tests to @chainsafe/swap-or-not-shuffle
interface ShuffleTestCase {
	id: string;
	rounds: number;
	seed: Uint8Array;
	input: Uint32Array;
	shuffled: string;
	unshuffled: string;
}

function fromHex(hexInput: string): Uint8Array {
	let hex = hexInput;
	if (typeof hex !== "string") {
		throw new Error(`hex argument type ${typeof hex} must be of type string`);
	}

	if (hex.startsWith("0x")) {
		hex = hex.slice(2);
	}

	if (hex.length % 2 !== 0) {
		throw new Error(`hex string length ${hex.length} must be multiple of 2`);
	}

	const b = Buffer.from(hex, "hex");
	return new Uint8Array(b.buffer, b.byteOffset, b.length);
}

function getInputArray(count: number): Uint32Array {
	return Uint32Array.from(Array.from({ length: count }, (_, i) => i));
}

function buildReferenceTestCase(
	count: number,
	rounds: number,
): ShuffleTestCase {
	const seed = randomBytes(32);
	const input = getInputArray(count);
	const shuffled = input.slice();
	referenceImplementation.shuffleList(shuffled, seed, rounds);
	const unshuffled = input.slice();
	referenceImplementation.unshuffleList(unshuffled, seed, rounds);
	return {
		id: `TestCase for ${count} indices with seed of $0x${seed.toString("hex")}`,
		seed,
		rounds,
		input,
		shuffled: Buffer.from(shuffled).toString("hex"),
		unshuffled: Buffer.from(unshuffled).toString("hex"),
	};
}

describe("shuffle", () => {
	it("should throw for invalid seed", () => {
		const test = buildReferenceTestCase(10, 10);
		let invalidSeed = Buffer.alloc(31, 0xac);
		expect(() => unshuffleList(test.input, invalidSeed, test.rounds)).toThrow(
			"Shuffling seed must be 32 bytes long",
		);
		invalidSeed = Buffer.alloc(33, 0xac);
		expect(() => unshuffleList(test.input, invalidSeed, test.rounds)).toThrow(
			"Shuffling seed must be 32 bytes long",
		);
	});

	it("should throw for invalid number of rounds", () => {
		const test = buildReferenceTestCase(10, 10);
		expect(() => unshuffleList(test.input, test.seed, -1)).toThrow(
			"Rounds must be between 0 and 255",
		);
		expect(() => unshuffleList(test.input, test.seed, 256)).toThrow(
			"Rounds must be between 0 and 255",
		);
	});

	/**
	 * Leave this test commented for github runners.  It fails on memory allocations. Leave in test suite
	 * to confirm that it does work though (local tests if you want to verify)
	 * TODO: not sure why Bun suspends creating a Buffer of 2**32 bytes
	 * but the implementation checks for max length of input already
	 */
	it.skip("should throw for invalid input array length", () => {
		const test = buildReferenceTestCase(10, 10);
		const input = Uint32Array.from(Buffer.alloc(2 ** 32, 0xac));
		expect(() => unshuffleList(input, test.seed, 100)).toThrow(
			"ActiveIndices must fit in a u32",
		);
	});

	it("should match spec test results", () => {
		const seed =
			"0x4fe91d85d6bc19b20413659c61f3c690a1c4d48be41cab8363a130cebabada97";
		const rounds = 10;
		const expected = Buffer.from([
			99, 71, 51, 5, 78, 61, 12, 17, 30, 3, 59, 47, 6, 9, 1, 41, 18, 37, 55, 43,
			20, 31, 38, 79, 29, 69, 70, 54, 53, 36, 34, 62, 77, 87, 39, 96, 56, 92,
			16, 82, 40, 27, 58, 14, 68, 76, 80, 13, 28, 81, 64, 26, 19, 60, 90, 2, 98,
			67, 66, 52, 46, 95, 49, 72, 8, 21, 75, 57, 97, 83, 84, 88, 86, 7, 74, 32,
			63, 85, 23, 65, 24, 91, 0, 48, 35, 15, 44, 25, 22, 73, 93, 45, 4, 33, 89,
			94, 10, 42, 11, 50,
		]).toString("hex");

		const result = unshuffleList(getInputArray(100), fromHex(seed), rounds);

		expect(Buffer.from(result).toString("hex")).toEqual(expected);
	});

	const testCases: ShuffleTestCase[] = [
		buildReferenceTestCase(8, 10),
		buildReferenceTestCase(16, 10),
		buildReferenceTestCase(16, 100),
		buildReferenceTestCase(256, 192),
		buildReferenceTestCase(256, 192),
	];

	for (const { id, seed, rounds, input, shuffled, unshuffled } of testCases) {
		it(`sync - ${id}`, () => {
			const unshuffledResult = unshuffleList(input, seed, rounds);
			const shuffledResult = shuffleList(input, seed, rounds);
			expect(Buffer.from(shuffledResult).toString("hex")).toEqual(shuffled);
			expect(Buffer.from(unshuffledResult).toString("hex")).toEqual(unshuffled);
		});
		it(`async - ${id}`, async () => {
			const unshuffledResult = await asyncUnshuffleList(input, seed, rounds);
			const shuffledResult = await asyncShuffleList(input, seed, rounds);
			expect(Buffer.from(shuffledResult).toString("hex")).toEqual(shuffled);
			expect(Buffer.from(unshuffledResult).toString("hex")).toEqual(unshuffled);
		});
	}
});
