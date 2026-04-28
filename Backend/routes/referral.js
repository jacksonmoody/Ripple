import { Router } from "express";
import { ObjectId } from "mongodb";
import { getDb } from "../auth.js";

const router = Router();

// POST /api/referral — record who referred the current user (called once after signup)
router.post("/", async (req, res) => {
  const { inviteCode } = req.body;
  if (!inviteCode || typeof inviteCode !== "string") {
    return res.status(400).json({ error: "inviteCode is required" });
  }

  const db = await getDb();
  const userId = req.session.user.id;

  const user = await db
    .collection("user")
    .findOne({ _id: new ObjectId(userId) });

  if (user?.referredBy) {
    return res.json({ success: true, alreadySet: true });
  }

  const referrer = await db
    .collection("user")
    .findOne({ inviteCode }, { projection: { _id: 1 } });

  if (!referrer) {
    return res.status(400).json({ error: "Invalid invite" });
  }

  const referrerId = referrer._id.toString();
  if (referrerId === userId) {
    return res.status(400).json({ error: "Cannot refer yourself" });
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
