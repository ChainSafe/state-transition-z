import path from "node:path";
import { openLibrary } from "@chainsafe/bun-ffi-z";

const fns = {
	createPubkeyIndexMap: {
		args: [],
		returns: "ptr",
	},
	destroyPubkeyIndexMap: {
		args: ["ptr"],
		returns: "void",
	},
	getNotFoundIndex: {
		args: [],
		returns: "u32",
	},
	getErrorIndex: {
		args: [],
		returns: "u32",
	},
	pubkeyIndexMapSet: {
		args: ["ptr", "ptr", "u32", "u32"],
		returns: "u32",
	},
	pubkeyIndexMapGet: {
		args: ["ptr", "ptr", "u32"],
		returns: "u32",
	},
	pubkeyIndexMapClear: {
		args: ["ptr"],
		returns: "void",
	},
	pubkeyIndexMapClone: {
		args: ["ptr"],
		returns: "ptr",
	},
	pubkeyIndexMapHas: {
		args: ["ptr", "ptr", "u32"],
		returns: "bool",
	},
	pubkeyIndexMapDelete: {
		args: ["ptr", "ptr", "u32"],
		returns: "bool",
	},
	pubkeyIndexMapSize: {
		args: ["ptr"],
		returns: "u32",
	},
	// binding for shuffe
	shuffleList: {
		args: ["ptr", "u32", "ptr", "u32", "u8"],
		returns: "u32",
	},
	unshuffleList: {
		args: ["ptr", "u32", "ptr", "u32", "u8"],
		returns: "u32",
	},
	asyncShuffleList: {
		args: ["ptr", "u32", "ptr", "u32", "u8"],
		returns: "u32",
	},
	asyncUnshuffleList: {
		args: ["ptr", "u32", "ptr", "u32", "u8"],
		returns: "u32",
	},
	pollAsyncResult: {
		args: ["u32"],
		returns: "u32",
	},
	releaseAsyncResult: {
		args: ["u32"],
		returns: "void",
	},
	computeProposerIndexElectra: {
		args: ["ptr", "u32", "ptr", "u32", "ptr", "u32", "u64", "u32", "u32"],
		returns: "u32",
	},
	computeProposerIndex: {
		args: ["ptr", "u32", "ptr", "u32", "ptr", "u32", "u8", "u64", "u32", "u32"],
		returns: "u32",
	},
	computeSyncCommitteeIndicesElectra: {
		args: [
			"ptr",
			"u32",
			"ptr",
			"u32",
			"ptr",
			"u32",
			"u64",
			"u32",
			"u32",
			"ptr",
			"u32",
		],
		returns: "u32",
	},
	computeSyncCommitteeIndices: {
		arts: [
			"ptr",
			"u32",
			"ptr",
			"u32",
			"ptr",
			"u32",
			"u8",
			"u64",
			"u32",
			"u32",
			"ptr",
			"u32",
		],
		returns: "u32",
	},
};

// Load the compiled Zig shared library
const lib = await openLibrary(path.resolve("."), fns);
export const binding = lib.symbols;

/**
 * Call this api to close the binding.
 */
export const close = lib.close;
