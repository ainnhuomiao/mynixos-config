import z from "@deepseek-ai/schemastery";
import { credentialRef } from "@deepseek-ai/dsh-credentials";
import {
  installSettingsSection,
  settingsNamespace,
} from "@deepseek-ai/dsh-settings";
import { launchEnvironmentOf } from "@deepseek-ai/dsh-launch-environment";
import { WebError } from "@deepseek-ai/dsh-web";

/**
 * Tavily-backed search provider for the harness web capability seam (`ctx.web`).
 * Calls `POST {baseURL}/search` directly; the wire format is provider-private and
 * does not use `ctx.llm`. Mirrors the structure of `dsh-web-search-deepseek`:
 * per-call option projection, credential resolution through `ctx.credentials`,
 * and optional session request logging.
 * @module dsh-web-search-tavily
 */

/** Stable id this provider registers under. */
const TAVILY_PROVIDER_ID = "tavily";
/** Default Tavily endpoint (`/search` is appended). */
const DEFAULT_BASE_URL = "https://api.tavily.com";
/** Default credential reference, resolved per search. */
const DEFAULT_API_KEY_ENV = "TAVILY_API_KEY";
/** Attribution header sent on every request. Bump with the package version. */
const USER_AGENT = "dsh-web-search-tavily/0.1.0";

/**
 * Clamp `max_results` to Tavily's per-depth caps (basic: 10, advanced: 20).
 * @param maxResults - configured positive integer.
 * @param searchDepth - normalized "basic" | "advanced".
 * @returns the clamped positive integer.
 */
function clampMaxResults(maxResults, searchDepth) {
  const cap = searchDepth === "advanced" ? 20 : 10;
  return Math.min(Math.max(1, Math.trunc(maxResults)), cap);
}

/**
 * Map a Tavily `/search` response to the seam's normalized `WebSearchResult`.
 * Dedupes `results[]` by URL; `content` → `snippet`, `published_date` →
 * `publishedAt`. Tavily's own `answer` prose is provider-generated text and is
 * deliberately NOT trusted as `content` (same stance as the DeepSeek provider).
 * @param data - the parsed Tavily response body.
 * @returns the normalized result (truncation is the seam's job, so `truncated` is always false).
 */
function mapTavilyResponse(data) {
  const seen = /* @__PURE__ */ new Set();
  const sources = [];
  for (const item of data.results ?? []) {
    const url = typeof item.url === "string" ? item.url.trim() : "";
    if (url.length === 0 || seen.has(url)) continue;
    seen.add(url);
    sources.push({
      url,
      ...(typeof item.title === "string" && item.title.length > 0
        ? { title: item.title }
        : {}),
      ...(typeof item.content === "string" && item.content.length > 0
        ? { snippet: item.content }
        : {}),
      ...(typeof item.published_date === "string" &&
      item.published_date.length > 0
        ? { publishedAt: item.published_date }
        : {}),
    });
  }
  return {
    sources,
    truncated: false,
  };
}

/** The Tavily-backed search provider; HTTP redirects fail as `WEB_PROVIDER_ERROR`. */
var TavilySearchProvider = class {
  resolveOptions;
  id = TAVILY_PROVIDER_ID;
  /**
   * @param resolveOptions - the options for the NEXT operation, snapshotted
   * once at each operation's entry so one search never mixes two sections.
   */
  constructor(resolveOptions) {
    this.resolveOptions = resolveOptions;
  }
  available() {
    const options = this.resolveOptions();
    return (
      ((options.apiKey?.length ?? 0) > 0 || options.resolveApiKey !== void 0) &&
      URL.canParse(options.baseURL)
    );
  }
  async search(request, signal) {
    const options = this.resolveOptions();
    const apiKey = await this.apiKey(options, signal);
    throwIfSearchAborted(signal);
    const endpoint = `${options.baseURL.replace(/\/+$/u, "")}/search`;
    const body = {
      query: request.query,
      search_depth: options.searchDepth,
      max_results: clampMaxResults(options.maxResults, options.searchDepth),
      include_answer: false,
    };
    options.recordRequest?.({ endpoint, body });
    throwIfSearchAborted(signal);
    let response;
    try {
      response = await fetch(endpoint, {
        method: "POST",
        redirect: "error",
        headers: {
          authorization: `Bearer ${apiKey}`,
          "content-type": "application/json",
          accept: "application/json",
          "user-agent": USER_AGENT,
        },
        body: JSON.stringify(body),
        ...(signal !== void 0 ? { signal } : {}),
      });
    } catch (error) {
      if (signal?.aborted === true || isAbortError(error))
        throw searchAborted(signal, error);
      throw new WebError(
        `Tavily search request failed: ${String(error)}`,
        "WEB_PROVIDER_ERROR",
        { cause: error },
      );
    }
    if (!response.ok) {
      let message = `Tavily API error (HTTP ${response.status})`;
      try {
        const parsed = await response.json();
        const detail =
          typeof parsed.error === "string"
            ? parsed.error
            : (parsed.error?.message ?? parsed.detail ?? parsed.message);
        if (detail !== void 0 && String(detail).length > 0)
          message = `Tavily API error: ${String(detail)}`;
      } catch (error) {
        if (signal?.aborted === true || isAbortError(error))
          throw searchAborted(signal, error);
      }
      throw new WebError(message, "WEB_PROVIDER_ERROR");
    }
    let data;
    try {
      data = await response.json();
    } catch (error) {
      if (signal?.aborted === true || isAbortError(error))
        throw searchAborted(signal, error);
      throw new WebError(
        `Tavily returned an unprocessable response body: ${String(error)}`,
        "WEB_PROVIDER_ERROR",
        { cause: error },
      );
    }
    return mapTavilyResponse(data);
  }
  /**
   * Resolve one operation's credential without retaining it on the provider.
   * @param options - the caller's snapshot, so the key and the endpoint it is sent to come from one section.
   * @param signal - abort signal for the surrounding search.
   * @returns the resolved key.
   */
  async apiKey(options, signal) {
    throwIfSearchAborted(signal);
    if (options.apiKey !== void 0 && options.apiKey.length > 0)
      return options.apiKey;
    let resolved;
    try {
      resolved = await abortable(
        options.resolveApiKey?.() ?? Promise.resolve(void 0),
        signal,
      );
    } catch (error) {
      if (signal?.aborted === true || isAbortError(error))
        throw searchAborted(signal, error);
      throw new WebError(
        `Tavily search credential resolution failed: ${String(error)}`,
        "WEB_PROVIDER_ERROR",
        { cause: error },
      );
    }
    if (resolved !== void 0 && resolved.length > 0) return resolved;
    throw new WebError(
      `Tavily search has no API key for "${options.apiKeyEnv ?? DEFAULT_API_KEY_ENV}"; store it through the credentials service, export it in the launching environment, or set a literal "apiKey" in the web-search-tavily config`,
      "WEB_PROVIDER_CREDENTIAL_MISSING",
    );
  }
};
/**
 * Race a same-process asynchronous preflight against caller cancellation.
 */
function abortable(operation, signal) {
  if (signal === void 0) return operation;
  if (signal.aborted) return Promise.reject(searchAborted(signal));
  return new Promise((resolve, reject) => {
    const onAbort = () => {
      reject(searchAborted(signal));
    };
    signal.addEventListener("abort", onAbort, { once: true });
    operation.then(
      (value) => {
        signal.removeEventListener("abort", onAbort);
        resolve(value);
      },
      (error) => {
        signal.removeEventListener("abort", onAbort);
        reject(
          new Error(String(error).replace(/^Error: /u, ""), { cause: error }),
        );
      },
    );
  });
}
/** Throw the provider's stable cancellation error when the caller already aborted. */
function throwIfSearchAborted(signal) {
  if (signal?.aborted === true) throw searchAborted(signal);
}
/** Build the provider's stable cancellation error while retaining the caller's reason. */
function searchAborted(signal, fallback) {
  return new WebError("Tavily search aborted", "WEB_ABORTED", {
    cause: signal?.aborted === true ? signal.reason : fallback,
  });
}
/** True for a fetch/`AbortSignal` abort, surfaced as `WEB_ABORTED`. */
function isAbortError(error) {
  return error instanceof DOMException && error.name === "AbortError";
}
/** Cordis plugin name used by loader diagnostics. */
const name = "web-search-tavily";
/** The web seam this provider registers into. */
const inject = ["web"];
const Config = z.object({
  apiKey: z.string().role("secret"),
  apiKeyEnv: z.string().role("credential-ref").default(DEFAULT_API_KEY_ENV),
  baseURL: z.string(),
  searchDepth: z.string().default("basic"),
  maxResults: z.number().step(1).min(1).default(5),
});
/** Settings namespace carrying this provider's endpoint, key reference, and behavior. */
const WEB_SEARCH_TAVILY_SETTINGS_NAMESPACE =
  settingsNamespace("web-search-tavily");
/**
 * Project one resolved section into the options the provider serves its next
 * search with. Every value it reads is already fully defaulted.
 * @param ctx - plugin context supplying the credential and environment planes.
 * @param config - the currently authoritative section.
 * @returns options for one search.
 */
function resolveOptions(ctx, config) {
  const apiKeyEnv = credentialRef(config.apiKeyEnv ?? DEFAULT_API_KEY_ENV);
  const literalApiKey =
    config.apiKey !== void 0 && config.apiKey.length > 0
      ? config.apiKey
      : void 0;
  return {
    ...(literalApiKey === void 0 ? {} : { apiKey: literalApiKey }),
    resolveApiKey: async () => {
      const credentials = ctx.get("credentials");
      if (credentials !== void 0)
        return (await credentials.resolve(apiKeyEnv))?.value;
      const ambient = launchEnvironmentOf(ctx).get(apiKeyEnv);
      return ambient !== void 0 && ambient.value.length > 0
        ? ambient.value
        : void 0;
    },
    apiKeyEnv,
    baseURL: config.baseURL ?? DEFAULT_BASE_URL,
    searchDepth: config.searchDepth === "advanced" ? "advanced" : "basic",
    maxResults: config.maxResults ?? 5,
    recordRequest: (request) => {
      try {
        ctx
          .get("agents")
          ?.currentInitiator()
          ?.session.append("web/tavily-search-request", request);
      } catch {
        // Observability must never break the search itself.
      }
    },
  };
}
/** Register the Tavily search provider with `ctx.web`. */
function apply(ctx, config) {
  let current = () => config;
  installSettingsSection(
    ctx,
    WEB_SEARCH_TAVILY_SETTINGS_NAMESPACE,
    Config,
    config,
    {
      setSource: (source) => {
        current = source;
      },
      onChange: () => {},
    },
  );
  ctx.web.registerSearchProvider(
    new TavilySearchProvider(() => resolveOptions(ctx, current())),
  );
}
export {
  Config,
  TAVILY_PROVIDER_ID,
  TavilySearchProvider,
  WEB_SEARCH_TAVILY_SETTINGS_NAMESPACE,
  apply,
  inject,
  name,
};
