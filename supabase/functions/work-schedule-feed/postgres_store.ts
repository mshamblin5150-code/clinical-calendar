import type { FeedStart, FeedStore, FetchCompletion, RelayMetadata } from "./relay.ts";

export class PostgresFeedStore implements FeedStore {
  constructor(
    private readonly supabaseUrl: string,
    private readonly publishableKey: string,
    private readonly request: typeof fetch = fetch,
  ) {}

  async start(feedId: string, authorization: string): Promise<FeedStart> {
    const response = await this.rpc(
      "claim_work_schedule_feed_relay",
      { p_feed_id: feedId },
      authorization,
    );
    if (response.status === 401 || response.status === 403) return { kind: "unauthenticated" };
    if (!response.ok) throw new Error(`feed_store_start_${response.status}`);
    return await response.json() as FeedStart;
  }

  async finish(completion: FetchCompletion): Promise<RelayMetadata> {
    const response = await this.rpc(
      "finish_work_schedule_feed_relay",
      {
        p_feed_id: completion.feedId,
        p_lease_token: completion.leaseToken,
        p_fetched_at_utc: completion.fetchedAt,
        p_upstream_status: completion.upstreamStatus,
        p_ics_text: completion.ics,
        p_etag: completion.etag,
        p_last_modified: completion.lastModified,
        p_error_class: completion.errorClass,
      },
      completion.authorization,
    );
    if (!response.ok) throw new Error(`feed_store_finish_${response.status}`);
    return await response.json() as RelayMetadata;
  }

  private rpc(
    name: string,
    body: Record<string, unknown>,
    authorization: string,
  ): Promise<Response> {
    return this.request(`${this.supabaseUrl}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: {
        apikey: this.publishableKey,
        authorization,
        "content-type": "application/json",
      },
      body: JSON.stringify(body),
    });
  }
}

export function readPublishableKey(environment: Record<string, string | undefined>): string {
  const keys = environment.SUPABASE_PUBLISHABLE_KEYS;
  if (keys) {
    const parsed = JSON.parse(keys) as Record<string, string>;
    if (parsed.default) return parsed.default;
  }
  const legacy = environment.SUPABASE_ANON_KEY;
  if (legacy) return legacy;
  throw new Error("Supabase publishable key is unavailable");
}
