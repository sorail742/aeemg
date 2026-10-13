import { assertEquals } from "jsr:@std/assert@1";
import { authorizeCron, createHandler, CRON_SECRET_HEADER, secretsEqual } from "./auth.ts";

const SECRET = "secret-de-test-0123456789"; // gitleaks:allow (valeur de test)
// Forme d'une clé anon Supabase (JWT) : elle ne doit pas suffire.
const ANON_KEY = "eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoiYW5vbiJ9.signature"; // gitleaks:allow (factice)

function post(headers: Record<string, string> = {}): Request {
  return new Request("http://localhost/event-reminders", { method: "POST", headers });
}

function handler(calls: { count: number }, options: { secret?: string } = { secret: SECRET }) {
  return createHandler({
    secret: options.secret,
    sendReminders: () => {
      calls.count++;
      return Promise.resolve({ notifications: 3 });
    },
  });
}

Deno.test("sans secret → 401, aucun rappel envoyé", async () => {
  const calls = { count: 0 };
  const res = await handler(calls)(post());
  assertEquals(res.status, 401);
  assertEquals(calls.count, 0);
});

Deno.test("avec la clé anon → 401, aucun rappel envoyé", async () => {
  const calls = { count: 0 };
  const res = await handler(calls)(
    post({ Authorization: `Bearer ${ANON_KEY}`, apikey: ANON_KEY }),
  );
  assertEquals(res.status, 401);
  assertEquals(calls.count, 0);
});

Deno.test("avec un mauvais secret → 401", async () => {
  const calls = { count: 0 };
  const res = await handler(calls)(post({ [CRON_SECRET_HEADER]: `${SECRET}x` }));
  assertEquals(res.status, 401);
  assertEquals(calls.count, 0);
});

Deno.test("avec le secret → 200 et rappels envoyés", async () => {
  const calls = { count: 0 };
  const res = await handler(calls)(post({ [CRON_SECRET_HEADER]: SECRET }));
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { ok: true, notifications: 3 });
  assertEquals(calls.count, 1);
});

Deno.test("CRON_SECRET absent côté serveur → 500, même avec un en-tête", async () => {
  const calls = { count: 0 };
  const res = await handler(calls, {})(post({ [CRON_SECRET_HEADER]: "" }));
  assertEquals(res.status, 500);
  assertEquals(calls.count, 0);
});

Deno.test("GET → 405", async () => {
  const res = await handler({ count: 0 })(
    new Request("http://localhost/event-reminders", { headers: { [CRON_SECRET_HEADER]: SECRET } }),
  );
  assertEquals(res.status, 405);
});

Deno.test("erreur interne → 500 sans détail", async () => {
  const res = await createHandler({
    secret: SECRET,
    sendReminders: () => Promise.reject(new Error('relation "events" does not exist')),
  })(post({ [CRON_SECRET_HEADER]: SECRET }));
  assertEquals(res.status, 500);
  assertEquals(await res.json(), { error: "Échec de l'envoi des rappels" });
});

Deno.test("secretsEqual compare le contenu, pas seulement la longueur", async () => {
  assertEquals(await secretsEqual("abc", "abc"), true);
  assertEquals(await secretsEqual("abc", "abd"), false);
  assertEquals(await secretsEqual("abc", "abcd"), false);
  assertEquals(await secretsEqual("", "abc"), false);
});

Deno.test("authorizeCron sans secret configuré refuse même un en-tête vide", async () => {
  assertEquals((await authorizeCron(post({ [CRON_SECRET_HEADER]: "" }), "")).ok, false);
});
