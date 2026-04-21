import { Router } from "express";
import { ObjectId } from "mongodb";
import { getDb } from "../auth.js";

const router = Router();

// GET /api/profile — get the authenticated user's profile with stats
router.get("/", async (req, res) => {
  const db = await getDb();
  const userId = req.session.user.id;
  const user = await db.collection("user").findOne({ _id: new ObjectId(userId) });

  const rallyCount = await db
    .collection("rallies")
    .countDocuments({ userId });

  const firstRally = await db
    .collection("rallies")
    .findOne({ userId }, { sort: { createdAt: 1 } });

  const uniqueContacts = await db
    .collection("rallies")
    .aggregate([
      { $match: { userId } },
      { $group: { _id: "$contactPhone" } },
      { $count: "count" },
    ])
    .toArray();

  const baseURL = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3005}`;
  const hasAvatar = !!user?.avatarFileId;

  return res.json({
    id: userId,
    name: user?.name || null,
    phoneNumber: user?.phoneNumber || req.session.user.phoneNumber || null,
    createdAt: user?.createdAt || null,
    rallyCount,
    uniqueContactsRallied: uniqueContacts[0]?.count ?? 0,
    firstRallyAt: firstRally?.createdAt || null,
    avatarUrl: hasAvatar
      ? `${baseURL}/api/profile/avatar/${userId}`
      : null,
  });
});

// PUT /api/profile — update the authenticated user's profile
router.put("/", async (req, res) => {
  const { name } = req.body;
  if (typeof name !== "string" || name.trim().length === 0) {
    return res.status(400).json({ error: "name is required" });
  }

  const db = await getDb();
  await db
    .collection("user")
    .updateOne({ _id: new ObjectId(req.session.user.id) }, { $set: { name: name.trim() } });

  return res.json({ success: true, name: name.trim() });
});

export default router;
