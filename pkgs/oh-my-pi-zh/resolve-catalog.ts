// Resolve workspace dependency specs to pinned versions for offline install.
//
// Bun may re-resolve `catalog:` and ranged workspace dependency specifiers
// against the npm registry on every `bun install`, even with a fully populated
// cache and `--frozen-lockfile` / `--offline`. In a Nix sandbox this fails. The
// lockfile already records the selected version for every direct package, so
// rewrite those specs to exact versions (or `workspace:*` for local packages)
// in bun.lock and every workspace package.json before `bun install` runs.
//
// Invoked as: bun resolve-catalog.ts <bunRoot>

import { join, resolve } from "node:path";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { pathToFileURL } from "node:url";

type Deps = Record<string, string>;
type DepHolder = Partial<
  Record<
    | "dependencies"
    | "devDependencies"
    | "peerDependencies"
    | "optionalDependencies",
    Deps
  >
>;
interface BunLock {
  workspaces?: Record<string, DepHolder>;
  catalog?: Deps;
  catalogs?: Record<string, Deps>;
  packages?: Record<string, [string, ...unknown[]]>;
}

const depSections = [
  "dependencies",
  "devDependencies",
  "peerDependencies",
  "optionalDependencies",
] as const;

const root = process.argv[2] ?? ".";
const lockPath = join(root, "bun.lock");

if (!existsSync(lockPath)) process.exit(0);

// bun.lock is JSON-with-trailing-commas. Bun's module loader has a built-in
// JSONC parser (used for tsconfig.json / bun.lock) that we can reach via
// `import(..., { with: { type: "jsonc" } })`. This works on every bun
// version supported by nixos-25.11+ (>= 1.3.3), unlike `Bun.JSONC` which
// only appeared in 1.3.6.
const lock = (
  (await import(pathToFileURL(resolve(lockPath)).href, {
    with: { type: "jsonc" },
  })) as { default: BunLock }
).default;

const catalog = lock.catalog ?? {};
const catalogs = lock.catalogs ?? {};
const packages = lock.packages ?? {};
const workspaces = lock.workspaces ?? {};

// Build name -> exact-version map from .packages. Only keep entries whose
// spec starts with "<name>@", i.e. the top-level resolution for that name.
const resolved: Deps = {};
for (const [name, entry] of Object.entries(packages)) {
  const spec = entry?.[0];
  if (typeof spec !== "string") continue;
  const prefix = `${name}@`;
  if (!spec.startsWith(prefix)) continue;
  resolved[name] = spec.slice(prefix.length);
}

function resolveSpec(name: string, spec: string): string {
  const rv = resolved[name];
  if (typeof rv === "string" && rv.startsWith("workspace:")) {
    return "workspace:*";
  }

  if (spec.startsWith("catalog:")) {
    const cname = spec.slice("catalog:".length);
    const table = cname === "" ? catalog : (catalogs[cname] ?? {});
    const cv = table[name];
    if (typeof cv === "string" && cv.startsWith("workspace:")) {
      return "workspace:*";
    }
    if (typeof rv === "string") return rv;
    if (typeof cv === "string") return cv;
    return spec;
  }

  // Preserve exact versions and non-registry protocols. Ranges such as
  // `^1.2.3` are pinned to the version already selected by bun.lock.
  const exactVersion =
    /^v?\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$/;
  if (exactVersion.test(spec) || /^[A-Za-z][A-Za-z+.-]*:/.test(spec)) {
    return spec;
  }
  if (typeof rv === "string") return rv;
  return spec;
}

function rewriteDeps(holder: DepHolder): boolean {
  let changed = false;
  for (const section of depSections) {
    const deps = holder[section];
    if (!deps || typeof deps !== "object") continue;
    for (const [name, spec] of Object.entries(deps)) {
      if (typeof spec !== "string") continue;
      const replacement = resolveSpec(name, spec);
      if (replacement !== spec) {
        deps[name] = replacement;
        changed = true;
      }
    }
  }
  return changed;
}

console.log("bun2nix: pinning workspace dependencies from bun.lock");

// Rewrite the lockfile's workspaces section, then normalize JSONC to JSON so
// the package derivation can remove patchedDependencies without another parser.
for (const ws of Object.values(workspaces)) rewriteDeps(ws);
writeFileSync(lockPath, JSON.stringify(lock, null, 2) + "\n");

// Synchronize dependency sections in each package.json with the rewritten lock
// workspace. This prevents any remaining source ranges from invalidating the
// frozen lock and triggering registry manifest lookups.
for (const [wsDir, ws] of Object.entries(workspaces)) {
  const pkgJson = join(root, wsDir, "package.json");
  if (!existsSync(pkgJson)) continue;
  const pkg = JSON.parse(readFileSync(pkgJson, "utf8")) as DepHolder;
  let changed = false;
  for (const section of depSections) {
    const locked = ws[section];
    if (!locked) continue;
    pkg[section] = { ...locked };
    changed = true;
  }
  if (changed) {
    writeFileSync(pkgJson, JSON.stringify(pkg, null, 2) + "\n");
  }
}
