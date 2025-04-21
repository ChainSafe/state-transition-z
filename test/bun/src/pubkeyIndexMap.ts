import { binding } from "./binding.js";

// this is to sync the constant from zig to Bun which is 0xffffffff
const NOT_FOUND_INDEX = binding.getNotFoundIndex();

/**
 * Bun bindings for PubkeyIndexMap zig implementation.
 * This has the same interface to the napi-rs implementation in https://github.com/ChainSafe/pubkey-index-map/blob/main/index.d.ts
 */
export class PubkeyIndexMap {
	// even through zig returns u64, it's safe to use number at Bun side
	// see https://bun.sh/docs/api/ffi#pointers
	private native_ptr: number;
	constructor() {
		const pointer = binding.createPubkeyIndexMap();
		if (pointer == null) {
			throw new Error("Failed to create PubkeyIndexMap");
		}
		this.native_ptr = pointer;
	}

	get(key: Uint8Array): number | null {
		const index = binding.pubkeyIndexMapGet(this.native_ptr, key, key.length);
		if (index === NOT_FOUND_INDEX) {
			return null;
		}
		return index;
	}

	set(key: Uint8Array, value: number): void {
		const res = binding.pubkeyIndexMapSet(
			this.native_ptr,
			key,
			key.length,
			value,
		);
		if (res !== 0) {
			throw new Error("Failed to set value in PubkeyIndexMap");
		}
	}

	has(key: Uint8Array): boolean {
		return binding.pubkeyIndexMapHas(this.native_ptr, key, key.length);
	}

	size(): number {
		return binding.pubkeyIndexMapSize(this.native_ptr);
	}

	delete(key: Uint8Array): boolean {
		return binding.pubkeyIndexMapDelete(this.native_ptr, key, key.length);
	}

	clear(): void {
		binding.pubkeyIndexMapClear(this.native_ptr);
	}
}
