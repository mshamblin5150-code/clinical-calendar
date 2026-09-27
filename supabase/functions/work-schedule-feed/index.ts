import { PostgresFeedStore, readPublishableKey } from "./postgres_store.ts";
import { createRelayHandler } from "./relay.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL");
if (!supabaseUrl) throw new Error("SUPABASE_URL is unavailable");

const store = new PostgresFeedStore(
  supabaseUrl,
  readPublishableKey({
    SUPABASE_PUBLISHABLE_KEYS: Deno.env.get("SUPABASE_PUBLISHABLE_KEYS"),
    SUPABASE_ANON_KEY: Deno.env.get("SUPABASE_ANON_KEY"),
  }),
);

Deno.serve(createRelayHandler({ store }));
