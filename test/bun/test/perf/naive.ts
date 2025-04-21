function toMemoryEfficientHexStr(hex: Uint8Array | string): string {
  if (typeof hex === "string") {
    if (hex.startsWith("0x")) {
      hex = hex.slice(2);
    }
    return hex;
  }

  return Buffer.from(hex.buffer, hex.byteOffset, hex.byteLength).toString("hex");
}

export class PubkeyIndexMap {
  // We don't really need the full pubkey. We could just use the first 20 bytes like an Ethereum address
  readonly map = new Map<string, number>();

  get size(): number {
    return this.map.size;
  }

  /**
   * Must support reading with string for API support where pubkeys are already strings
   */
  get(key: Uint8Array | string): number | undefined {
    return this.map.get(toMemoryEfficientHexStr(key));
  }

  set(key: Uint8Array, value: number): void {
    this.map.set(toMemoryEfficientHexStr(key), value);
  }
}
