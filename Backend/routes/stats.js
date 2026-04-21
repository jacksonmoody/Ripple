import { Router } from "express";
import { getDb } from "../auth.js";

const router = Router();

// GET /api/stats — aggregated stats for the authenticated user
router.get("/", async (req, res) => {
  const db = await getDb();
  const userId = req.session.user.id;

  const rallyCount = await db
    .collection("rallies")
    .countDocuments({ userId });

  const totalUsers = await db
    .collection("rallies")
    .aggregate([{ $group: { _id: "$userId" } }, { $count: "count" }])
    .toArray();

  const totalRallies = await db.collection("rallies").countDocuments();

  const recentRallies = await db
    .collection("rallies")
    .find({ userId })
    .sort({ createdAt: -1 })
    .limit(10)
    .toArray();

  return res.json({
    rallyCount,
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
