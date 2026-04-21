import { Router } from "express";
import { getDb } from "../auth.js";

const router = Router();

// Shared helper: compute score for a given userId
export async function computeUserScore(db, userId) {
  const textsSent = await db
    .collection("rallies")
    .countDocuments({ userId });

  const directSignups = await db
    .collection("user")
    .countDocuments({ referredBy: userId });

  const directReferralIds = await db
    .collection("user")
    .find({ referredBy: userId })
    .project({ _id: 1 })
    .toArray();
  const directIds = directReferralIds.map((u) => u._id.toString());

  let secondDegreeSignups = 0;
  if (directIds.length > 0) {
    secondDegreeSignups = await db
      .collection("user")
      .countDocuments({ referredBy: { $in: directIds } });
  }

  const textsPoints = textsSent * 10;
  const signupsPoints = directSignups * 50;
  const secondDegreePoints = secondDegreeSignups * 5;

  return {
    textsSent,
    directSignups,
    secondDegreeSignups,
    score: textsPoints + signupsPoints + secondDegreePoints,
    breakdown: { textsPoints, signupsPoints, secondDegreePoints },
  };
}

// GET /api/stats — aggregated stats for the authenticated user
router.get("/", async (req, res) => {
  const db = await getDb();
  const userId = req.session.user.id;

  const [scoreData, recentRallies] = await Promise.all([
    computeUserScore(db, userId),
    db
      .collection("rallies")
      .find({ userId })
      .sort({ createdAt: -1 })
      .limit(10)
      .toArray(),
  ]);

  const totalUsers = await db
    .collection("rallies")
    .aggregate([{ $group: { _id: "$userId" } }, { $count: "count" }])
    .toArray();

  const totalRallies = await db.collection("rallies").countDocuments();

  return res.json({
    ...scoreData,
    rallyCount: scoreData.textsSent,
    totalUsersRallying: totalUsers[0]?.count ?? 0,
    totalRalliesNetwork: totalRallies,
    recentRallies: recentRallies.map((n) => ({
      id: n._id.toString(),
      contactName: n.contactName,
      createdAt: n.createdAt,
    })),
  });
});

export default router;
