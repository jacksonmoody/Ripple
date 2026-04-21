import "dotenv/config";
import express from "express";
import cors from "cors";
import { toNodeHandler, fromNodeHeaders } from "better-auth/node";
import { auth } from "./auth.js";

import ralliesRouter from "./routes/rallies.js";
import leaderboardRouter from "./routes/leaderboard.js";
import statsRouter from "./routes/stats.js";
import profileRouter from "./routes/profile.js";
import avatarRouter from "./routes/avatar.js";
import referralRouter from "./routes/referral.js";

const app = express();
const port = process.env.PORT || 3005;

app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
  }),
);

// Better Auth handles its own routes
app.all("/api/auth/*splat", toNodeHandler(auth));

app.use(express.json());

// Middleware: require authenticated session and attach to req.session
async function requireSession(req, res, next) {
  const session = await auth.api.getSession({
    headers: fromNodeHeaders(req.headers),
  });
  if (!session) {
    return res.status(401).json({ error: "Not authenticated" });
  }
  req.session = session;
  next();
}

// Avatar routes first — GET is public, POST/DELETE handle their own auth
app.use("/api/profile/avatar", avatarRouter);

// Authenticated routes
app.get("/api/me", requireSession, (req, res) => res.json(req.session));
app.use("/api/rallies", requireSession, ralliesRouter);
app.use("/api/leaderboard", requireSession, leaderboardRouter);
app.use("/api/stats", requireSession, statsRouter);
app.use("/api/profile", requireSession, profileRouter);
app.use("/api/referral", requireSession, referralRouter);

app.listen(port, () => {
  console.log(`Ripple backend running on http://localhost:${port}`);
});
