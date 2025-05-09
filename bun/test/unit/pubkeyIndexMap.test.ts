import { describe, expect, it, beforeAll } from "bun:test";
import { PubkeyIndexMap, initBinding } from "../../src/index.js";

describe("PubkeyIndexMap", () => {
  beforeAll(async () => {
    await initBinding();
  });

	it("should init/populate/get/set/remove/clear", () => {
		const map = new PubkeyIndexMap();
		expect(map.size()).toBe(0);

		const pubkey = new Uint8Array(Buffer.alloc(48)).slice();
		const index = 42;
		expect(map.has(pubkey)).toBe(false);

		const p = new Uint8Array(1000);
		expect(map.has(p.subarray(0, 48))).toBe(false);

		// Add a pubkey
		map.set(pubkey, index);
		map.set(pubkey, index + 1);
		map.set(pubkey, index);

		expect(map.size()).toBe(1);
		expect(map.get(pubkey)).toBe(index);
		expect(map.get(pubkey.slice())).toBe(index);
		expect(map.has(pubkey)).toBe(true);
		expect(map.has(pubkey.slice())).toBe(true);

		// Add another pubkey
		const pubkey2 = new Uint8Array(Buffer.alloc(48, 1)).slice();
		const index2 = 43;
		map.set(pubkey2, index2);

		expect(map.size()).toBe(2);
		expect(map.get(pubkey2)).toBe(index2);

		// Remove a pubkey
		map.delete(pubkey);
		expect(map.size()).toBe(1);
		// this is not found
		expect(map.get(pubkey)).toBe(null);
		expect(map.get(pubkey2)).toBe(index2);

		// Clear the map
		map.clear();

		expect(map.size()).toBe(0);
		expect(map.get(pubkey)).toBe(null);
		expect(map.get(pubkey2)).toBe(null);

		// Ensure different instances of the same pubkey are treated as the same
		const pubkey3 = pubkey.slice();
		const index3 = 44;
		map.set(pubkey, index);
		map.set(pubkey3, index3);

		expect(map.get(pubkey)).toBe(index3);
		expect(map.get(pubkey3)).toBe(index3);
	});
});
