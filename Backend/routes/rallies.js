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

  // Look up Ripple profiles for rallied phone numbers
  const uniquePhones = [...new Set(rallies.map((r) => r.contactPhone).filter(Boolean))];
  const normalizePhone = (p) => p.replace(/\D/g, "").slice(-10);

  const users = await db
    .collection("user")
    .find({ phoneNumber: { $in: uniquePhones } })
    .toArray();

  const baseURL = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3005}`;
  const contactProfiles = {};
  for (const user of users) {
    const phone = user.phoneNumber;
    if (!phone) continue;
    const normalized = normalizePhone(phone);
    const hasName = user.name && !user.name.startsWith("+");
    contactProfiles[normalized] = {
      name: hasName ? user.name : null,
      avatarUrl: user.avatarFileId
        ? `${baseURL}/api/profile/avatar/${user._id.toString()}`
        : null,
    };
  }

  return res.json({
    rallies: rallies.map((n) => ({
      id: n._id.toString(),
      contactName: n.contactName,
      contactPhone: n.contactPhone,
      createdAt: n.createdAt,
    })),
    total: rallies.length,
    contactProfiles,
  });
});

export default router;
