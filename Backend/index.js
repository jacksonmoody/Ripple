import "dotenv/config";
import express from "express";
import cors from "cors";
import { toNodeHandler, fromNodeHeaders } from "better-auth/node";
import { auth } from "./auth.js";
import smartmatchRouter from "./smartmatch.js";

const app = express();
const port = process.env.PORT || 3005;

app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"],
    credentials: true,
  })
);

app.all("/api/auth/*splat", toNodeHandler(auth));

app.use(express.json());

app.use("/api/smartmatch", smartmatchRouter);

app.get("/api/me", async (req, res) => {
  const session = await auth.api.getSession({
    headers: fromNodeHeaders(req.headers),
  });
  if (!session) {
    return res.status(401).json({ error: "Not authenticated" });
  }
  return res.json(session);
});

app.listen(port, () => {
  console.log(`Ripple backend running on http://localhost:${port}`);
  console.log(`Auth endpoints at http://localhost:${port}/api/auth/*`);
  console.log(`Health check: http://localhost:${port}/api/auth/ok`);
});
