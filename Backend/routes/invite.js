import { Router } from "express";
import { randomBytes } from "crypto";
import { ObjectId } from "mongodb";
import { fromNodeHeaders } from "better-auth/node";
import { auth, getDb } from "../auth.js";

const router = Router();

const appName = "Ripple";

function getPublicOrigin(req) {
  if (process.env.BASE_URL) return process.env.BASE_URL.replace(/\/$/, "");

  const proto = req.get("x-forwarded-proto") || req.protocol;
  const host = req.get("x-forwarded-host") || req.get("host");
  return `${proto}://${host}`;
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function buildInviteUrls(req, inviteCode) {
  const origin = getPublicOrigin(req);
  const encodedInviteCode = encodeURIComponent(inviteCode);

  return {
    inviteUrl: `${origin}/invite/${encodedInviteCode}`,
    publicInviteUrl: `${origin}/invite/${encodedInviteCode}`,
    appDeepLink: `ripple://invite/${encodedInviteCode}`,
  };
}

function createInviteCode() {
  return randomBytes(12).toString("base64url");
}

async function generateUniqueInviteCode(db) {
  for (let attempt = 0; attempt < 5; attempt += 1) {
    const inviteCode = createInviteCode();
    const existing = await db
      .collection("user")
      .findOne({ inviteCode }, { projection: { _id: 1 } });
    if (!existing) return inviteCode;
  }

  throw new Error("Could not generate a unique invite code");
}

async function getOrCreateInviteForUser(userId) {
  if (!ObjectId.isValid(userId)) return null;

  const db = await getDb();
  const userObjectId = new ObjectId(userId);

  for (let attempt = 0; attempt < 5; attempt += 1) {
    const user = await db
      .collection("user")
      .findOne(
        { _id: userObjectId },
        { projection: { name: 1, inviteCode: 1 } },
      );

    if (!user) return null;

    if (user.inviteCode) {
      return {
        inviteCode: user.inviteCode,
        referrerName: user.name || "A friend",
      };
    }

    const inviteCode = await generateUniqueInviteCode(db);
    try {
      const result = await db.collection("user").updateOne(
        {
          _id: userObjectId,
          $or: [
            { inviteCode: { $exists: false } },
            { inviteCode: null },
            { inviteCode: "" },
          ],
        },
        { $set: { inviteCode } },
      );

      if (result.modifiedCount === 1) {
        return {
          inviteCode,
          referrerName: user.name || "A friend",
        };
      }
    } catch (error) {
      if (error?.code !== 11000) throw error;
    }
  }

  throw new Error("Could not assign an invite code");
}

async function findInviteByCode(inviteCode) {
  if (!inviteCode || typeof inviteCode !== "string") return null;

  const db = await getDb();
  const user = await db
    .collection("user")
    .findOne({ inviteCode }, { projection: { name: 1, inviteCode: 1 } });

  if (!user) return null;

  return {
    inviteCode: user.inviteCode,
    referrerName: user.name || "A friend",
  };
}

function invitePayload(req, invite) {
  const urls = buildInviteUrls(req, invite.inviteCode);

  return {
    appName,
    inviteCode: invite.inviteCode,
    referrerName: invite.referrerName,
    inviteUrl: urls.inviteUrl,
    publicInviteUrl: urls.publicInviteUrl,
    appDeepLink: urls.appDeepLink,
    message: `${invite.referrerName} invited you to join ${appName}.`,
  };
}

// GET /api/invite/me — authenticated helper for the current user's share link
router.get("/api/invite/me", async (req, res) => {
  const session = await auth.api.getSession({
    headers: fromNodeHeaders(req.headers),
  });

  if (!session) {
    return res.status(401).json({ error: "Not authenticated" });
  }

  const invite = await getOrCreateInviteForUser(session.user.id);
  if (!invite) {
    return res.status(404).json({ error: "Invite owner not found" });
  }

  return res.json(invitePayload(req, invite));
});

// GET /api/invite/:inviteCode — public invite metadata
router.get("/api/invite/:inviteCode", async (req, res) => {
  const { inviteCode } = req.params;
  const invite = await findInviteByCode(inviteCode);
  if (!invite) {
    return res.status(404).json({ error: "Invite not found" });
  }

  return res.json(invitePayload(req, invite));
});

// GET /invite/:inviteCode — public browser landing page
router.get("/invite/:inviteCode", async (req, res) => {
  const { inviteCode } = req.params;
  const invite = await findInviteByCode(inviteCode);
  if (!invite) {
    return res.status(404).type("html").send(renderMissingInvitePage(req));
  }

  return res
    .type("html")
    .send(renderInvitePage(req, invitePayload(req, invite)));
});

function renderMissingInvitePage(req) {
  const origin = getPublicOrigin(req);
  return renderPage({
    title: "Ripple Invite Not Found",
    description: "This Ripple invite could not be found.",
    canonicalUrl: `${origin}/invite`,
    body: `
      <main class="shell">
        <section class="card">
          <div class="mark">~</div>
          <p class="eyebrow">Ripple</p>
          <h1>Invite not found</h1>
          <p class="copy">This invite link is missing or no longer valid.</p>
        </section>
      </main>
    `,
  });
}

function renderInvitePage(req, invite) {
  const safeName = escapeHtml(invite.referrerName);
  const safeInviteUrl = escapeHtml(invite.inviteUrl);
  const safeDeepLink = escapeHtml(invite.appDeepLink);
  const safeDescription = escapeHtml(invite.message);

  return renderPage({
    title: `${safeName} invited you to Ripple`,
    description: safeDescription,
    canonicalUrl: safeInviteUrl,
    body: `
      <main class="shell">
        <section class="card">
          <div class="ripples" aria-hidden="true">
            <span></span>
            <span></span>
            <span></span>
          </div>
          <div class="mark">~</div>
          <p class="eyebrow">Ripple invite</p>
          <h1>${safeName} invited you to join Ripple</h1>
          <p class="copy">Join their network and help turn the tide.</p>
          <div class="actions">
            <a class="button primary" href="${safeDeepLink}">Open Ripple</a>
            <a class="button secondary" href="${safeInviteUrl}">Copy Invite Link</a>
          </div>
        </section>
      </main>
      <script>
        window.setTimeout(function () {
          window.location.href = ${JSON.stringify(invite.appDeepLink)};
        }, 450);
      </script>
    `,
  });
}

function renderPage({ title, description, canonicalUrl, body }) {
  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>${title}</title>
    <meta name="description" content="${description}" />
    <meta property="og:title" content="${title}" />
    <meta property="og:description" content="${description}" />
    <meta property="og:type" content="website" />
    <meta property="og:url" content="${canonicalUrl}" />
    <link rel="canonical" href="${canonicalUrl}" />
    <style>
      :root {
        color-scheme: light;
        --blue: #405ccc;
        --blue-dark: #1f348f;
        --surface: #ffffff;
        --text: #16204a;
        --muted: #657092;
      }

      * {
        box-sizing: border-box;
      }

      body {
        margin: 0;
        min-height: 100vh;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background:
          radial-gradient(circle at 50% 22%, rgba(64, 92, 204, 0.18), transparent 32rem),
          linear-gradient(135deg, #f7f9ff, #edf2ff);
        color: var(--text);
      }

      .shell {
        min-height: 100vh;
        display: grid;
        place-items: center;
        padding: 24px;
      }

      .card {
        width: min(100%, 430px);
        position: relative;
        overflow: hidden;
        padding: 44px 28px 32px;
        border: 1px solid rgba(64, 92, 204, 0.12);
        border-radius: 28px;
        background: rgba(255, 255, 255, 0.86);
        box-shadow: 0 24px 70px rgba(31, 52, 143, 0.16);
        text-align: center;
      }

      .ripples {
        position: absolute;
        inset: 0;
        display: grid;
        place-items: center;
        pointer-events: none;
      }

      .ripples span {
        position: absolute;
        width: 140px;
        height: 140px;
        border: 2px solid rgba(64, 92, 204, 0.16);
        border-radius: 999px;
        animation: ripple 2.4s ease-out infinite;
      }

      .ripples span:nth-child(2) {
        animation-delay: 0.35s;
      }

      .ripples span:nth-child(3) {
        animation-delay: 0.7s;
      }

      .mark {
        width: 68px;
        height: 68px;
        position: relative;
        z-index: 1;
        display: grid;
        place-items: center;
        margin: 0 auto 18px;
        border-radius: 999px;
        background: var(--blue);
        color: white;
        font-size: 42px;
        line-height: 1;
        font-weight: 700;
        box-shadow: 0 18px 38px rgba(64, 92, 204, 0.24);
      }

      .eyebrow {
        position: relative;
        z-index: 1;
        margin: 0 0 10px;
        color: var(--blue);
        font-size: 13px;
        font-weight: 700;
        letter-spacing: 0.08em;
        text-transform: uppercase;
      }

      h1 {
        position: relative;
        z-index: 1;
        margin: 0;
        font-size: clamp(32px, 9vw, 42px);
        line-height: 1.02;
        letter-spacing: 0;
      }

      .copy {
        position: relative;
        z-index: 1;
        margin: 16px 0 0;
        color: var(--muted);
        font-size: 17px;
        line-height: 1.45;
      }

      .actions {
        position: relative;
        z-index: 1;
        display: grid;
        gap: 12px;
        margin-top: 28px;
      }

      .button {
        display: block;
        padding: 15px 18px;
        border-radius: 999px;
        font-size: 16px;
        font-weight: 700;
        text-decoration: none;
      }

      .primary {
        background: var(--blue);
        color: white;
        box-shadow: 0 14px 28px rgba(64, 92, 204, 0.22);
      }

      .secondary {
        color: var(--blue-dark);
        background: rgba(64, 92, 204, 0.08);
      }

      @keyframes ripple {
        0% {
          opacity: 0.72;
          transform: scale(0.45);
        }
        100% {
          opacity: 0;
          transform: scale(2.2);
        }
      }

      @media (prefers-reduced-motion: reduce) {
        .ripples span {
          animation: none;
          opacity: 0.24;
        }
      }
    </style>
  </head>
  <body>
    ${body}
  </body>
</html>`;
}

export default router;
