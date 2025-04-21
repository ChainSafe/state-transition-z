import {randomBytes} from "crypto";
import {describe} from "@chainsafe/benchmark";
import {bench} from "@chainsafe/benchmark";

import {PubkeyIndexMap} from "../../src/pubkeyIndexMap.js";
import {PubkeyIndexMap as PubkeyIndexMapNaive} from "./naive.js";

describe("get/set", () => {
  for (const N of [1_000, 1_000_000]) {
    const p0 = new PubkeyIndexMap();
    const p1 = new PubkeyIndexMapNaive();
    const pks = Array.from({length: N}, (_, i) => randomBytes(48));
    for (let i = 0; i < N; i++) {
      p0.set(pks[i], 0);
      p1.set(pks[i], 0);
    }

    bench({
      id: `get values - ${N}`,
      beforeEach: () => {
        return Math.floor(Math.random() * N);
      },
      fn: (n) => {
        p0.get(pks[n]);
      }
    });

    bench({
      id: `get values - naive - ${N}`,
      beforeEach: () => {
        return Math.floor(Math.random() * N);
      },
      fn: (n) => {
        p1.get(pks[n]);
      }
    });
    bench({
      id: `set values - ${N}`,
      beforeEach: () => {
        return Math.floor(Math.random() * N);
      },
      fn: (n) => {
        p0.set(pks[n], 0);
      }
    });

    bench({
      id: `set values - naive - ${N}`,
      beforeEach: () => {
        return Math.floor(Math.random() * N);
      },
      fn: (n) => {
        p1.set(pks[n], 0);
      }
    });
  }
});
