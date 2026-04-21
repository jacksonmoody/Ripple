import { Router } from "express";
import { getDb } from "../auth.js";

const router = Router();

// POST /api/rallies — record rallies sent by the user
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

  await db.collection("rallies").insertMany(docs);

  return res.json({ success: true, count: docs.length });
});

// GET /api/rallies — get the authenticated user's rallies
router.get("/", async (req, res) => {
  const db = await getDb();
  const rallies = await db
    .collection("rallies")
    .find({ userId: req.session.user.id })
    .sort({ createdAt: -1 })
    .toArray();

  return res.json({
    rallies: rallies.map((n) => ({
      id: n._id.toString(),
      contactName: n.contactName,
      contactPhone: n.contactPhone,
      createdAt: n.createdAt,
    })),
    total: rallies.length,
  });
});

export default router;
