import { assertEquals } from "jsr:@std/assert@1";
import { createHandler, type Dependencies, refusalFromPostgres } from "./handler.ts";

const TARGET = "00000000-0000-0000-0000-00000000a104";
const BEARER = "Bearer jeton-de-test"; // gitleaks:allow (factice)

function deps(overrides: Partial<Dependencies> = {}) {
  const calls: string[] = [];
  const d: Dependencies = {
    authorize: () => Promise.resolve(null),
    listObjects: () =>
      Promise.resolve([
        { bucket_id: "avatars", name: `${TARGET}/photo.jpg` },
        { bucket_id: "chat_images", name: "groupe/a.jpg" },
        { bucket_id: "chat_images", name: "groupe/b.jpg" },
      ]),
    removeObjects: (bucket, names) => {
      calls.push(`remove ${bucket} ${names.length}`);
      return Promise.resolve();
    },
    deleteUser: (id) => {
      calls.push(`delete ${id}`);
      return Promise.resolve();
    },
    ...overrides,
  };
  return { d, calls };
}

function post(body: unknown, authorization: string | null = BEARER): Request {
  const headers: Record<string, string> = { "content-type": "application/json" };
  if (authorization) headers.Authorization = authorization;
  return new Request("http://localhost/admin-delete-user", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

Deno.test("sans JWT → 401, rien n'est supprimé", async () => {
  const { d, calls } = deps();
  const res = await createHandler(d)(post({ user_id: TARGET }, null));
  assertEquals(res.status, 401);
  assertEquals(calls, []);
});

Deno.test("user_id invalide → 400", async () => {
  const { d, calls } = deps();
  const res = await createHandler(d)(post({ user_id: "pas-un-uuid" }));
  assertEquals(res.status, 400);
  assertEquals(calls, []);
});

Deno.test("refus de check_member_deletion → 403, rien n'est supprimé", async () => {
  const { d, calls } = deps({
    authorize: () =>
      Promise.resolve(
        refusalFromPostgres({ code: "42501", message: "Seul un administrateur peut supprimer" }),
      ),
  });
  const res = await createHandler(d)(post({ user_id: TARGET }));
  assertEquals(res.status, 403);
  assertEquals((await res.json()).error, "Seul un administrateur peut supprimer");
  assertEquals(calls, []);
});

Deno.test("membre introuvable → 404", () => {
  assertEquals(refusalFromPostgres({ code: "P0002" })?.status, 404);
  assertEquals(refusalFromPostgres({ code: "XX000" })?.status, 500);
  assertEquals(refusalFromPostgres(null), null);
});

Deno.test("autorisé → fichiers supprimés par bucket, puis le compte", async () => {
  const { d, calls } = deps();
  const res = await createHandler(d)(post({ user_id: TARGET }));
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { ok: true, files: 3 });
  assertEquals(calls, ["remove avatars 1", "remove chat_images 2", `delete ${TARGET}`]);
});

Deno.test("échec Storage → 500 et le compte n'est pas supprimé", async () => {
  const { d, calls } = deps({ removeObjects: () => Promise.reject(new Error("storage")) });
  const res = await createHandler(d)(post({ user_id: TARGET }));
  assertEquals(res.status, 500);
  assertEquals(calls, []);
});

Deno.test("OPTIONS → en-têtes CORS pour l'app web", async () => {
  const { d } = deps();
  const res = await createHandler(d)(new Request("http://localhost/", { method: "OPTIONS" }));
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("Access-Control-Allow-Methods"), "POST, OPTIONS");
});
