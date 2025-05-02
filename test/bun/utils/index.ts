import { resolve } from "node:path";
export const BINDINGS_NAME = "libstate-transition-utils";

export const ROOT_DIR = resolve(__dirname, "../../..");
export const PREBUILD_DIR = resolve(ROOT_DIR, "zig-out/lib");

class NotBunError extends Error {
	constructor(missingItem: string) {
		super(
			`blst-bun bindings only run in a Bun context. No ${missingItem} found.`,
		);
	}
}

/**
 * Get shared library name according to blst-z release artifacts
 * for example: https://github.com/ChainSafe/blst-z/releases/tag/v0.1.0-rc.0
 * name: libblst_min_pk_{arch}-{platform}.{ext}
 */
export function getBinaryName(): string {
	if (!process) throw new NotBunError("global object");
	const platform = process.platform;
	if (!platform) throw new NotBunError("process.platform");

	// shared library extension
	let ext: string;
	switch (platform) {
		case "darwin":
			ext = "dylib";
			break;
		case "linux":
			ext = "so";
			break;
		case "win32":
			ext = "dll";
			break;
		default:
			throw new Error(`Unsupported platform: ${platform}`);
	}

	// return `${BINDINGS_NAME}_${archName}-${platformName}.${ext}`;
	// for dev
	return `${BINDINGS_NAME}.${ext}`;
}

export function getPrebuiltBinaryPath(binaryName: string): string {
	return resolve(PREBUILD_DIR, binaryName);
}
