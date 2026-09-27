import { PinnedHttpsError, pinnedHttpsFetch } from "./pinned_https.ts";

export type RelayErrorClass =
  | "method_not_allowed"
  | "invalid_request"
  | "feed_not_found"
  | "unauthenticated"
  | "fetch_in_progress"
  | "ssrf_refused"
  | "invalid_feed_url"
  | "redirect_limit"
  | "invalid_redirect"
  | "size_limit"
  | "time_limit"
  | "upstream_unavailable"
  | "upstream_status"
  | "invalid_304";

export interface RelayMetadata {
  ics: string | null;
  fetchedAt: string | null;
  upstreamStatus: number | null;
  fromCache: boolean;
  errorClass: RelayErrorClass | null;
}

export type FeedStart =
  | { kind: "not_found" }
  | { kind: "unauthenticated" }
  | { kind: "cached"; result: RelayMetadata }
  | {
    kind: "fetch";
    feedId: string;
    leaseToken: string;
    url: string;
    etag: string | null;
    lastModified: string | null;
    cachedIcs: string | null;
  };

export interface FeedStore {
  start(feedId: string, authorization: string): Promise<FeedStart>;
  finish(completion: FetchCompletion): Promise<RelayMetadata>;
}

export interface FetchCompletion {
  feedId: string;
  leaseToken: string;
  fetchedAt: string;
  upstreamStatus: number | null;
  ics: string | null;
  etag: string | null;
  lastModified: string | null;
  errorClass: RelayErrorClass | null;
  authorization: string;
}

export interface RelayDependencies {
  store: FeedStore;
  fetch?: typeof fetch;
  resolveDns?: (hostname: string) => Promise<string[]>;
  now?: () => Date;
  maxResponseBytes?: number;
  timeoutMs?: number;
}

const emptyResult = (errorClass: RelayErrorClass): RelayMetadata => ({
  ics: null,
  fetchedAt: null,
  upstreamStatus: null,
  fromCache: false,
  errorClass,
});

export function createRelayHandler(dependencies: RelayDependencies) {
  return async (request: Request): Promise<Response> => {
    if (request.method !== "POST") {
      return Response.json(emptyResult("method_not_allowed"), { status: 405 });
    }

    const authorization = request.headers.get("authorization") ?? "";
    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return Response.json(emptyResult("invalid_request"), { status: 400 });
    }

    const requestKeys = isRecord(body) ? Object.keys(body) : [];
    const feedId = isRecord(body) && typeof body.feedId === "string" ? body.feedId : null;
    if (
      requestKeys.length !== 1 || requestKeys[0] !== "feedId" || !feedId || !isUuid(feedId) ||
      !authorization.startsWith("Bearer ")
    ) {
      return Response.json(emptyResult("invalid_request"), { status: 400 });
    }

    const start = await dependencies.store.start(feedId, authorization);
    if (start.kind === "not_found") {
      return Response.json(emptyResult("feed_not_found"), { status: 404 });
    }
    if (start.kind === "unauthenticated") {
      return Response.json(emptyResult("unauthenticated"), { status: 401 });
    }
    if (start.kind === "cached") {
      const status = start.result.errorClass === "fetch_in_progress"
        ? 503
        : start.result.errorClass
        ? 502
        : 200;
      return Response.json(start.result, { status });
    }

    try {
      const upstream = await fetchFollowingSafeRedirects(start, dependencies);
      const fetchedAt = (dependencies.now ?? (() => new Date()))().toISOString();
      const result = await dependencies.store.finish({
        feedId: start.feedId,
        leaseToken: start.leaseToken,
        fetchedAt,
        upstreamStatus: upstream.status,
        ics: upstream.ics,
        etag: upstream.etag,
        lastModified: upstream.lastModified,
        errorClass: null,
        authorization,
      });
      return Response.json(result);
    } catch (error) {
      const errorClass = error instanceof RelayError
        ? error.errorClass
        : error instanceof PinnedHttpsError && error.errorClass === "size_limit"
        ? "size_limit"
        : error instanceof DOMException && error.name === "TimeoutError"
        ? "time_limit"
        : "upstream_unavailable";
      const result = await dependencies.store.finish({
        feedId: start.feedId,
        leaseToken: start.leaseToken,
        fetchedAt: (dependencies.now ?? (() => new Date()))().toISOString(),
        upstreamStatus: error instanceof RelayError || error instanceof PinnedHttpsError
          ? error.upstreamStatus
          : null,
        ics: null,
        etag: null,
        lastModified: null,
        errorClass,
        authorization,
      });
      const status = errorClass === "ssrf_refused"
        ? 403
        : errorClass === "size_limit"
        ? 413
        : errorClass === "time_limit"
        ? 504
        : 502;
      return Response.json(result, { status });
    }
  };
}

class RelayError extends Error {
  constructor(readonly errorClass: RelayErrorClass, readonly upstreamStatus: number | null = null) {
    super(errorClass);
  }
}

interface UpstreamResult {
  status: number;
  ics: string | null;
  etag: string | null;
  lastModified: string | null;
}

async function fetchFollowingSafeRedirects(
  start: Extract<FeedStart, { kind: "fetch" }>,
  dependencies: RelayDependencies,
): Promise<UpstreamResult> {
  let target = normalizeSavedUrl(start.url);
  const signal = AbortSignal.timeout(dependencies.timeoutMs ?? 10_000);
  const maxResponseBytes = dependencies.maxResponseBytes ?? 3 * 1024 * 1024;
  const headers = new Headers({ accept: "text/calendar, text/plain;q=0.9" });
  if (start.etag) headers.set("if-none-match", start.etag);
  if (start.lastModified) headers.set("if-modified-since", start.lastModified);

  for (let redirectCount = 0; redirectCount <= 3; redirectCount += 1) {
    const address = await resolvePublicTarget(
      target,
      dependencies.resolveDns ?? defaultResolveDns,
      signal,
    );
    const response = dependencies.fetch
      ? await dependencies.fetch(target, { headers, redirect: "manual", signal })
      : await pinnedHttpsFetch(target, address, { headers, maxResponseBytes, signal });
    if (isRedirect(response.status)) {
      if (redirectCount === 3) throw new RelayError("redirect_limit", response.status);
      const location = response.headers.get("location");
      if (!location) throw new RelayError("invalid_redirect", response.status);
      target = normalizeSavedUrl(new URL(location, target).toString());
      continue;
    }
    if (response.status !== 304 && (response.status < 200 || response.status >= 300)) {
      await response.body?.cancel();
      throw new RelayError("upstream_status", response.status);
    }
    if (response.status === 304 && start.cachedIcs === null) {
      throw new RelayError("invalid_304", response.status);
    }
    return {
      status: response.status,
      ics: response.status === 304
        ? start.cachedIcs
        : await readBoundedText(response, maxResponseBytes),
      etag: response.headers.get("etag"),
      lastModified: response.headers.get("last-modified"),
    };
  }
  throw new RelayError("redirect_limit");
}

async function readBoundedText(response: Response, maxBytes: number): Promise<string> {
  const declaredLength = response.headers.get("content-length");
  if (declaredLength !== null && Number(declaredLength) > maxBytes) {
    await response.body?.cancel();
    throw new RelayError("size_limit", response.status);
  }
  if (!response.body) return "";

  const reader = response.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > maxBytes) {
        await reader.cancel();
        throw new RelayError("size_limit", response.status);
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }

  const bytes = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder("utf-8", { fatal: true }).decode(bytes);
}

function normalizeSavedUrl(raw: string): URL {
  let candidate = raw;
  if (candidate.toLowerCase().startsWith("webcal://")) {
    candidate = `https://${candidate.slice("webcal://".length)}`;
  }
  let url: URL;
  try {
    url = new URL(candidate);
  } catch {
    throw new RelayError("invalid_feed_url");
  }
  if (url.protocol !== "https:" || url.username || url.password) {
    throw new RelayError("invalid_feed_url");
  }
  return url;
}

async function resolvePublicTarget(
  url: URL,
  resolveDns: (hostname: string) => Promise<string[]>,
  signal: AbortSignal,
): Promise<string> {
  const hostname = url.hostname.replace(/^\[|\]$/g, "");
  const addresses = isIpAddress(hostname)
    ? [hostname]
    : await raceWithAbort(resolveDns(hostname), signal);
  if (addresses.length === 0 || addresses.some(isNonPublicAddress)) {
    throw new RelayError("ssrf_refused");
  }
  return addresses[0];
}

function raceWithAbort<T>(operation: Promise<T>, signal: AbortSignal): Promise<T> {
  if (signal.aborted) return Promise.reject(signal.reason);
  return new Promise<T>((resolve, reject) => {
    const abort = () => reject(signal.reason);
    signal.addEventListener("abort", abort, { once: true });
    operation.then(
      (value) => {
        signal.removeEventListener("abort", abort);
        resolve(value);
      },
      (error) => {
        signal.removeEventListener("abort", abort);
        reject(error);
      },
    );
  });
}

async function defaultResolveDns(hostname: string): Promise<string[]> {
  const [ipv4, ipv6] = await Promise.all([
    Deno.resolveDns(hostname, "A").catch(() => []),
    Deno.resolveDns(hostname, "AAAA").catch(() => []),
  ]);
  return [...ipv4, ...ipv6];
}

function isRedirect(status: number): boolean {
  return [301, 302, 303, 307, 308].includes(status);
}

function isIpAddress(value: string): boolean {
  return /^\d{1,3}(?:\.\d{1,3}){3}$/.test(value) || value.includes(":");
}

function isNonPublicAddress(value: string): boolean {
  const normalized = value.toLowerCase();
  if (normalized.includes(":")) {
    const segments = parseIpv6(normalized);
    if (!segments) return true;
    const first = segments[0];
    if (
      segments.every((segment) => segment === 0) ||
      (segments.slice(0, 7).every((segment) => segment === 0) && segments[7] === 1) ||
      (first & 0xfe00) === 0xfc00 || (first & 0xffc0) === 0xfe80 ||
      (first & 0xff00) === 0xff00
    ) return true;
    const mapped = segments.slice(0, 5).every((segment) => segment === 0) &&
      segments[5] === 0xffff;
    const compatible = segments.slice(0, 6).every((segment) => segment === 0);
    if (mapped || compatible) {
      return isNonPublicAddress(
        `${segments[6] >> 8}.${segments[6] & 255}.${segments[7] >> 8}.${segments[7] & 255}`,
      );
    }
    return false;
  }
  const octets = normalized.split(".").map(Number);
  if (
    octets.length !== 4 || octets.some((part) => !Number.isInteger(part) || part < 0 || part > 255)
  ) {
    return true;
  }
  const [a, b] = octets;
  return a === 0 || a === 10 || a === 127 ||
    (a === 100 && b >= 64 && b <= 127) ||
    (a === 169 && b === 254) ||
    (a === 172 && b >= 16 && b <= 31) ||
    (a === 192 && b === 168) || a >= 224;
}

function parseIpv6(value: string): number[] | null {
  let candidate = value;
  const dotted = candidate.match(/(\d+\.\d+\.\d+\.\d+)$/);
  if (dotted) {
    const octets = dotted[1].split(".").map(Number);
    if (octets.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) return null;
    candidate = `${candidate.slice(0, -dotted[1].length)}${
      ((octets[0] << 8) | octets[1]).toString(16)
    }:${((octets[2] << 8) | octets[3]).toString(16)}`;
  }
  const halves = candidate.split("::");
  if (halves.length > 2) return null;
  const left = halves[0] ? halves[0].split(":") : [];
  const right = halves.length === 2 && halves[1] ? halves[1].split(":") : [];
  if ([...left, ...right].some((part) => !/^[0-9a-f]{1,4}$/i.test(part))) return null;
  const missing = 8 - left.length - right.length;
  if ((halves.length === 1 && missing !== 0) || (halves.length === 2 && missing < 1)) return null;
  return [...left.map(hex), ...Array(missing).fill(0), ...right.map(hex)];
}

function hex(value: string): number {
  return Number.parseInt(value, 16);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isUuid(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}
