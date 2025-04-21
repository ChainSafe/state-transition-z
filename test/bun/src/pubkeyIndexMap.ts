import {binding} from "./binding.js";

export class PubkeyIndexMap {
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
		if (index === 0xffffffff) {
			return null;
		}
		return index;
	}

	set(key: Uint8Array, value: number): void {
		const res = binding.pubkeyIndexMapSet(this.native_ptr, key, key.length, value);
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
