#!/usr/bin/env -S deno run --allow-all --quiet

// example.ts script description short version
//
// This will remove any bla bla
// To see exactly what this
// will do, run:
//
//     sd activation example.ts
//
// (TypeScript on Deno: `deno run` executes it directly, no build step.)

async function main(): Promise<void> {
  console.log("Hello, world from Deno");
}

await main();
