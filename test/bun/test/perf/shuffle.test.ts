import { bench, describe } from "@chainsafe/benchmark";
import { unshuffleList } from "../../src/index.js";
import * as referenceImplementation from "../referenceImplementation.js";

const SHUFFLE_ROUNDS_MINIMAL = 10;
// TODO: below is Rust implementation, double check with Zig
//          Lighthouse  Lodestar
// 512      254.04 us  1.6034 ms (x6)
// 16384    6.2046 ms  18.272 ms (x3)
// 4000000  1.5617 s   4.9690 s  (x3)

for (const listSize of [
	16384, 250_000,
	1_000_000,
	// Don't run 4_000_000 since it's very slow and not testnet has gotten there yet
	// 4e6,
]) {
	describe(`shuffle list - ${listSize} indices`, () => {
		const seed = Buffer.alloc(32, 0xac);
		const input: number[] = [];
		for (let i = 0; i < listSize; i++) input[i] = i;
		const indices = new Uint32Array(input);

		bench<Uint32Array, Uint32Array>({
			id: `JS   - unshuffleList - ${listSize} indices`,
			fn: () => {
				referenceImplementation.unshuffleList(
					indices,
					seed,
					SHUFFLE_ROUNDS_MINIMAL,
				);
			},
		});

		bench<Uint32Array, Uint32Array>({
			id: `Zig - unshuffleList - ${listSize} indices`,
			fn: () => {
				unshuffleList(indices, seed, SHUFFLE_ROUNDS_MINIMAL);
			},
		});

		// skip this as Bun use polling solution
		// bench<Uint32Array, Uint32Array>({
		//   id: `Zig - asyncUnshuffleList - ${listSize} indices`,
		//   fn: async () => {
		//     await asyncUnshuffleList(indices, seed, SHUFFLE_ROUNDS_MINIMAL);
		//   },
		// });
	});
}
