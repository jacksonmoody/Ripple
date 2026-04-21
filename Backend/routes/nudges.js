import { Router } from "express";
import { getDb } from "../auth.js";

const router = Router();

// POST /api/nudges — record nudges sent by the user
router.post("/", async (req, res) => {
  const { contacts } = req.body;
  if (!Array.isArray(contacts) || contacts.length === 0) {
    return res.status(400).json({ error: "contacts array is required" });
  }

  const db = await getDb();
  const now = new Date();
  const docs = contacts.map((c) => ({
    userId: req.session.user.id,
    contactName: c.name || "",
    contactPhone: c.phone || "",
    createdAt: now,
  }));

  await db.collection("nudges").insertMany(docs);

  return res.json({ success: true, count: docs.length });
});

// GET /api/nudges — get the authenticated user's nudges
router.get("/", async (req, res) => {
  const db = await getDb();
  const nudges = await db
    .collection("nudges")
    .find({ userId: req.session.user.id })
    .sort({ createdAt: -1 })
    .toArray();

  return res.json({
    nudges: nudges.map((n) => ({
      id: n._id.toString(),
      contactName: n.contactName,
      contactPhone: n.contactPhone,
      createdAt: n.createdAt,
    })),
    total: nudges.length,
  });
});

export default router;
