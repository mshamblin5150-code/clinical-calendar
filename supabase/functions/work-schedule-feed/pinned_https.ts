export interface PinnedHttpsOptions {
  headers: Headers;
  maxResponseBytes: number;
  signal: AbortSignal;
}

export class PinnedHttpsError extends Error {
  constructor(
    readonly errorClass: "size_limit" | "invalid_upstream_response",
    readonly upstreamStatus: number | null = null,
  ) {
    super(errorClass);
  }
}

const maxHeaderBytes = 64 * 1024;

export async function pinnedHttpsFetch(
  url: URL,
  address: string,
  options: PinnedHttpsOptions,
): Promise<Response> {
  throwIfAborted(options.signal);
  const port = url.port ? Number(url.port) : 443;
  const tcp = await Deno.connect({ hostname: address, port, signal: options.signal });
  let connection: Deno.TlsConn | null = null;
  const closeOnAbort = () => {
    try {
      (connection ?? tcp).close();
    } catch {
      // The operation that observed the abort already closed the connection.
    }
  };
  options.signal.addEventListener("abort", closeOnAbort, { once: true });

  try {
    connection = await Deno.startTls(tcp, {
      hostname: url.hostname.replace(/^\[|\]$/g, ""),
      alpnProtocols: ["http/1.1"],
    });
    throwIfAborted(options.signal);
    await writeAll(connection, encodeRequest(url, options.headers));
    const wireBytes = await readToClose(
      connection,
      options.maxResponseBytes + maxHeaderBytes,
      options.signal,
    );
    return parseHttpResponse(wireBytes, options.maxResponseBytes);
  } catch (error) {
    if (options.signal.aborted) throw options.signal.reason;
    throw error;
  } finally {
    options.signal.removeEventListener("abort", closeOnAbort);
    try {
      (connection ?? tcp).close();
    } catch {
      // A completed or aborted peer can close first.
    }
  }
}

function encodeRequest(url: URL, suppliedHeaders: Headers): Uint8Array {
  const headers = new Headers(suppliedHeaders);
  headers.set("host", url.host);
  headers.set("connection", "close");
  headers.set("accept-encoding", "identity");
  headers.set("user-agent", "clinical-calendar-work-schedule-feed-relay/1");
  const path = `${url.pathname || "/"}${url.search}`;
  const lines = [`GET ${path} HTTP/1.1`];
  for (const [name, value] of headers) lines.push(`${name}: ${value}`);
  return new TextEncoder().encode(`${lines.join("\r\n")}\r\n\r\n`);
}

async function writeAll(
  writer: { write(bytes: Uint8Array): Promise<number> },
  bytes: Uint8Array,
): Promise<void> {
  let offset = 0;
  while (offset < bytes.length) offset += await writer.write(bytes.subarray(offset));
}

async function readToClose(
  reader: { read(buffer: Uint8Array): Promise<number | null> },
  maxWireBytes: number,
  signal: AbortSignal,
): Promise<Uint8Array> {
  const chunks: Uint8Array[] = [];
  let total = 0;
  while (true) {
    throwIfAborted(signal);
    const buffer = new Uint8Array(16 * 1024);
    const count = await reader.read(buffer);
    if (count === null) break;
    chunks.push(buffer.subarray(0, count));
    total += count;
    if (total > maxWireBytes) {
      throw new PinnedHttpsError("size_limit", statusFromPrefix(chunks));
    }
  }
  const result = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}

function parseHttpResponse(wireBytes: Uint8Array, maxBodyBytes: number): Response {
  const headerEnd = findSequence(wireBytes, new Uint8Array([13, 10, 13, 10]));
  if (headerEnd < 0 || headerEnd > maxHeaderBytes) {
    throw new PinnedHttpsError("invalid_upstream_response");
  }
  const headerText = new TextDecoder("latin1").decode(wireBytes.subarray(0, headerEnd));
  const [statusLine, ...headerLines] = headerText.split("\r\n");
  const statusMatch = statusLine.match(/^HTTP\/1\.[01] ([1-5][0-9]{2})(?: |$)/);
  if (!statusMatch) throw new PinnedHttpsError("invalid_upstream_response");
  const status = Number(statusMatch[1]);
  const headers = new Headers();
  for (const line of headerLines) {
    const separator = line.indexOf(":");
    if (separator <= 0) throw new PinnedHttpsError("invalid_upstream_response");
    headers.append(line.slice(0, separator).trim(), line.slice(separator + 1).trim());
  }

  const encodedBody = wireBytes.subarray(headerEnd + 4);
  let body: Uint8Array;
  if (headers.get("transfer-encoding")?.toLowerCase().includes("chunked")) {
    body = decodeChunked(encodedBody, maxBodyBytes, status);
  } else {
    const declared = headers.get("content-length");
    if (declared !== null) {
      const length = Number(declared);
      if (
        !Number.isSafeInteger(length) || length < 0 || length > maxBodyBytes ||
        encodedBody.length < length
      ) throw new PinnedHttpsError("size_limit", status);
      body = encodedBody.subarray(0, length);
    } else {
      body = encodedBody;
    }
  }
  if (body.length > maxBodyBytes) throw new PinnedHttpsError("size_limit", status);
  const responseBody = status === 204 || status === 304 ? null : Uint8Array.from(body).buffer;
  return new Response(responseBody, { status, headers });
}

function decodeChunked(encoded: Uint8Array, maxBodyBytes: number, status: number): Uint8Array {
  const chunks: Uint8Array[] = [];
  let total = 0;
  let offset = 0;
  while (true) {
    const lineEnd = findSequence(encoded, new Uint8Array([13, 10]), offset);
    if (lineEnd < 0) throw new PinnedHttpsError("invalid_upstream_response");
    const sizeText =
      new TextDecoder("ascii").decode(encoded.subarray(offset, lineEnd)).split(";", 1)[0];
    if (!/^[0-9a-f]+$/i.test(sizeText)) {
      throw new PinnedHttpsError("invalid_upstream_response");
    }
    const size = Number.parseInt(sizeText, 16);
    offset = lineEnd + 2;
    if (size === 0) break;
    if (
      offset + size + 2 > encoded.length || encoded[offset + size] !== 13 ||
      encoded[offset + size + 1] !== 10
    ) throw new PinnedHttpsError("invalid_upstream_response");
    total += size;
    if (total > maxBodyBytes) throw new PinnedHttpsError("size_limit", status);
    chunks.push(encoded.subarray(offset, offset + size));
    offset += size + 2;
  }
  const decoded = new Uint8Array(total);
  let writeOffset = 0;
  for (const chunk of chunks) {
    decoded.set(chunk, writeOffset);
    writeOffset += chunk.length;
  }
  return decoded;
}

function statusFromPrefix(chunks: Uint8Array[]): number | null {
  const prefix = new Uint8Array(32);
  let length = 0;
  for (const chunk of chunks) {
    const count = Math.min(chunk.length, prefix.length - length);
    prefix.set(chunk.subarray(0, count), length);
    length += count;
    if (length === prefix.length) break;
  }
  if (length === 0) return null;
  const match = new TextDecoder("ascii").decode(prefix.subarray(0, length)).match(
    /^HTTP\/1\.[01] ([1-5][0-9]{2})/,
  );
  return match ? Number(match[1]) : null;
}

function findSequence(haystack: Uint8Array, needle: Uint8Array, start = 0): number {
  outer:
  for (let index = start; index <= haystack.length - needle.length; index += 1) {
    for (let part = 0; part < needle.length; part += 1) {
      if (haystack[index + part] !== needle[part]) continue outer;
    }
    return index;
  }
  return -1;
}

function throwIfAborted(signal: AbortSignal): void {
  if (signal.aborted) throw signal.reason;
}
