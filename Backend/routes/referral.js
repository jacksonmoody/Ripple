import { Router } from "express";
import { ObjectId } from "mongodb";
import { getDb } from "../auth.js";

const router = Router();

// POST /api/referral — record who referred the current user (called once after signup)
router.post("/", async (req, res) => {
  const { referrerId } = req.body;
  if (!referrerId || typeof referrerId !== "string") {
    return res.status(400).json({ error: "referrerId is required" });
  }

  const db = await getDb();
  const userId = req.session.user.id;

  if (referrerId === userId) {
    return res.status(400).json({ error: "Cannot refer yourself" });
  }

  const user = await db
    .collection("user")
    .findOne({ _id: new ObjectId(userId) });

  if (user?.referredBy) {
    return res.json({ success: true, alreadySet: true });
  }

  // Verify the referrer exists
  const referrer = await db
    .collection("user")
    .findOne({ _id: new ObjectId(referrerId) });

  if (!referrer) {
    return res.status(400).json({ error: "Invalid referrer" });
  }

  await db
    .collection("user")
    .updateOne(
      { _id: new ObjectId(userId) },
      { $set: { referredBy: referrerId } }
    );

  return res.json({ success: true });
});

export default router;
