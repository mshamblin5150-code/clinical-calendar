import {
  createRelayHandler,
  type FeedStore,
  type FetchCompletion,
} from "../../work-schedule-feed/relay.ts";

function assertEquals(actual: unknown, expected: unknown): void {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(`Expected ${JSON.stringify(expected)}, received ${JSON.stringify(actual)}`);
  }
}

const feedId = "f6283a0e-0712-4ec2-8207-a063631bbceb";

function fetchStart(url: string) {
  return {
    kind: "fetch" as const,
    feedId,
    leaseToken: "lease-1",
    url,
    etag: null,
    lastModified: null,
    cachedIcs: null,
  };
}

function completingStore(url: string): FeedStore {
  return {
    start: () => Promise.resolve(fetchStart(url)),
    finish: (completion: FetchCompletion) =>
      Promise.resolve({
        ics: completion.ics,
        fetchedAt: completion.fetchedAt,
        upstreamStatus: completion.upstreamStatus,
        fromCache: completion.upstreamStatus === 304,
        errorClass: completion.errorClass,
      }),
  };
}

function relayRequest(body: Record<string, unknown> = { feedId }): Request {
  return new Request("https://local.test/work-schedule-feed", {
    method: "POST",
    headers: {
      authorization: "Bearer student-a",
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });
}

Deno.test("another Student's Work Schedule Feed is refused without an upstream request", async () => {
  let fetchCount = 0;
  const store: FeedStore = {
    start: () => Promise.resolve({ kind: "not_found" }),
    finish: () => Promise.reject(new Error("finish must not be called")),
  };
  const handler = createRelayHandler({
    store,
    fetch: () => {
      fetchCount += 1;
      return Promise.reject(new Error("fetch must not be called"));
    },
  });

  const response = await handler(
    new Request("https://local.test/work-schedule-feed", {
      method: "POST",
      headers: {
        authorization: "Bearer student-a",
        "content-type": "application/json",
      },
      body: JSON.stringify({ feedId: "f6283a0e-0712-4ec2-8207-a063631bbceb" }),
    }),
  );

  assertEquals(response.status, 404);
  assertEquals(await response.json(), {
    ics: null,
    fetchedAt: null,
    upstreamStatus: null,
    fromCache: false,
    errorClass: "feed_not_found",
  });
  assertEquals(fetchCount, 0);
});

Deno.test("loopback and private saved targets are refused", async () => {
  for (
    const address of [
      "127.0.0.1",
      "10.2.3.4",
      "169.254.169.254",
      "::1",
      "::ffff:7f00:1",
      "fd00::1",
    ]
  ) {
    let fetchCount = 0;
    const handler = createRelayHandler({
      store: completingStore("https://calendar.example/feed.ics"),
      resolveDns: () => Promise.resolve([address]),
      fetch: () => {
        fetchCount += 1;
        return Promise.resolve(new Response("must not happen"));
      },
    });

    const response = await handler(relayRequest());
    assertEquals(response.status, 403);
    assertEquals((await response.json()).errorClass, "ssrf_refused");
    assertEquals(fetchCount, 0);
  }
});

Deno.test("a redirect from a public host to a private host is refused", async () => {
  let fetchCount = 0;
  const handler = createRelayHandler({
    store: completingStore("https://calendar.example/feed.ics"),
    resolveDns: (hostname) =>
      Promise.resolve(hostname === "calendar.example" ? ["203.0.113.10"] : ["192.168.1.2"]),
    fetch: () => {
      fetchCount += 1;
      return Promise.resolve(
        new Response(null, {
          status: 302,
          headers: { location: "https://internal.example/feed.ics" },
        }),
      );
    },
  });

  const response = await handler(relayRequest());
  assertEquals(response.status, 403);
  assertEquals((await response.json()).errorClass, "ssrf_refused");
  assertEquals(fetchCount, 1);
});

Deno.test("an upstream body beyond the size cap is refused while streaming", async () => {
  const handler = createRelayHandler({
    store: completingStore("https://calendar.example/feed.ics"),
    resolveDns: () => Promise.resolve(["203.0.113.10"]),
    maxResponseBytes: 8,
    fetch: () => Promise.resolve(new Response("123456789")),
  });

  const response = await handler(relayRequest());
  assertEquals(response.status, 413);
  const result = await response.json();
  assertEquals(result.errorClass, "size_limit");
  assertEquals(result.upstreamStatus, 200);
});

Deno.test("the upstream fetch is aborted at the time cap", async () => {
  const handler = createRelayHandler({
    store: completingStore("https://calendar.example/feed.ics"),
    resolveDns: () => Promise.resolve(["203.0.113.10"]),
    timeoutMs: 5,
    fetch: (_input, init) =>
      new Promise<Response>((_resolve, reject) => {
        init?.signal?.addEventListener("abort", () => reject(init.signal?.reason), { once: true });
      }),
  });

  const response = await handler(relayRequest());
  assertEquals(response.status, 504);
  assertEquals((await response.json()).errorClass, "time_limit");
});

Deno.test("the same time cap includes DNS resolution", async () => {
  let fetchCount = 0;
  const handler = createRelayHandler({
    store: completingStore("https://calendar.example/feed.ics"),
    resolveDns: () => new Promise<string[]>(() => {}),
    timeoutMs: 5,
    fetch: () => {
      fetchCount += 1;
      return Promise.reject(new Error("fetch must not be called"));
    },
  });

  const response = await handler(relayRequest());
  assertEquals(response.status, 504);
  assertEquals((await response.json()).errorClass, "time_limit");
  assertEquals(fetchCount, 0);
});

Deno.test("plain HTTP is refused without logging the feed URL or token", async () => {
  const logged: unknown[][] = [];
  const originalError = console.error;
  console.error = (...values: unknown[]) => logged.push(values);
  try {
    const handler = createRelayHandler({
      store: completingStore("http://calendar.example/private-token-123.ics"),
      resolveDns: () => Promise.resolve(["203.0.113.10"]),
      fetch: () => Promise.reject(new Error("fetch must not be called")),
    });

    const response = await handler(relayRequest());
    assertEquals(response.status, 502);
    assertEquals((await response.json()).errorClass, "invalid_feed_url");
    assertEquals(logged, []);
  } finally {
    console.error = originalError;
  }
});

Deno.test("a request inside the 15-minute window receives the cached result", async () => {
  const cached = {
    ics: "BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n",
    fetchedAt: "2026-09-27T11:55:00.000Z",
    upstreamStatus: 200,
    fromCache: true,
    errorClass: null,
  };
  let fetchCount = 0;
  const handler = createRelayHandler({
    store: {
      start: () => Promise.resolve({ kind: "cached", result: cached }),
      finish: () => Promise.reject(new Error("finish must not be called")),
    },
    fetch: () => {
      fetchCount += 1;
      return Promise.reject(new Error("fetch must not be called"));
    },
  });

  const response = await handler(relayRequest());
  assertEquals(response.status, 200);
  assertEquals(await response.json(), cached);
  assertEquals(fetchCount, 0);
});

Deno.test("a stale cache sends validators and passes through a 304 with cached ICS", async () => {
  const sentHeaders: Headers[] = [];
  const store: FeedStore = {
    start: () =>
      Promise.resolve({
        ...fetchStart("webcal://calendar.example/feed.ics"),
        etag: '"feed-v1"',
        lastModified: "Sat, 26 Sep 2026 12:00:00 GMT",
        cachedIcs: "BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n",
      }),
    finish: (completion) =>
      Promise.resolve({
        ics: completion.ics,
        fetchedAt: completion.fetchedAt,
        upstreamStatus: completion.upstreamStatus,
        fromCache: completion.upstreamStatus === 304,
        errorClass: completion.errorClass,
      }),
  };
  const handler = createRelayHandler({
    store,
    now: () => new Date("2026-09-27T12:15:00.000Z"),
    resolveDns: () => Promise.resolve(["203.0.113.10"]),
    fetch: (input, init) => {
      assertEquals(input.toString(), "https://calendar.example/feed.ics");
      sentHeaders.push(new Headers(init?.headers));
      return Promise.resolve(new Response(null, { status: 304 }));
    },
  });

  const response = await handler(relayRequest());
  assertEquals(response.status, 200);
  assertEquals(await response.json(), {
    ics: "BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n",
    fetchedAt: "2026-09-27T12:15:00.000Z",
    upstreamStatus: 304,
    fromCache: true,
    errorClass: null,
  });
  assertEquals(sentHeaders[0]?.get("if-none-match"), '"feed-v1"');
  assertEquals(sentHeaders[0]?.get("if-modified-since"), "Sat, 26 Sep 2026 12:00:00 GMT");
});

Deno.test("an unsaved URL is refused instead of being used as an open proxy", async () => {
  let storeCalls = 0;
  const handler = createRelayHandler({
    store: {
      start: () => {
        storeCalls += 1;
        return Promise.resolve({ kind: "not_found" });
      },
      finish: () => Promise.reject(new Error("finish must not be called")),
    },
    fetch: () => Promise.reject(new Error("fetch must not be called")),
  });

  const response = await handler(
    new Request("https://local.test/work-schedule-feed", {
      method: "POST",
      headers: {
        authorization: "Bearer student-a",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        feedId: "f6283a0e-0712-4ec2-8207-a063631bbceb",
        url: "https://attacker.test/private.ics",
      }),
    }),
  );

  assertEquals(response.status, 400);
  assertEquals((await response.json()).errorClass, "invalid_request");
  assertEquals(storeCalls, 0);
});
