import {type ConvertFns, type Library} from "bun:ffi";
import {openLibrary, FFIFunction} from "@chainsafe/bun-ffi-z";

// import { dlopen } from "bun:ffi";
// import { getBinaryName, getPrebuiltBinaryPath } from "../utils/index.js";

// const binaryName = getBinaryName();
// const binaryPath = getPrebuiltBinaryPath(binaryName);

// export const binding = lib.symbols;

// export async function init(): Promise<Record<string, FFIFunction>> {

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

let binding : ConvertFns<typeof fns> | null = null;

// Load the compiled Zig shared library
const libPromise = await openLibrary(import.meta.dirname, fns);

export async function initBinding(): Promise<void> {
  const lib = await libPromise;
  binding = lib.symbols;
}

export function getBinding(): ConvertFns<typeof fns> {
  if (binding == null) {
    throw new Error("Binding not initialized. Call init() first.");
  }
  return binding;
}

export async function closeBinding(): Promise<void> {
  const lib = await libPromise;
	lib.close();
}
