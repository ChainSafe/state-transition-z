import { dlopen } from "bun:ffi";
import { getBinaryName, getPrebuiltBinaryPath } from "../utils/index.js";

const binaryName = getBinaryName();
const binaryPath = getPrebuiltBinaryPath(binaryName);

// Load the compiled Zig shared library
const lib = dlopen(binaryPath, {
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
});

export const binding = lib.symbols;

export function closeBinding(): void {
	lib.close();
}
