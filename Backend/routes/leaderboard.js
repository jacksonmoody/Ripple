import { Router } from "express";
import { getDb } from "../auth.js";

const router = Router();

// GET /api/leaderboard — ranked users by nudge count
router.get("/", async (req, res) => {
  const db = await getDb();

  const pipeline = [
    { $group: { _id: "$userId", nudgeCount: { $sum: 1 } } },
    { $sort: { nudgeCount: -1 } },
    { $limit: 20 },
  ];

  const ranked = await db.collection("nudges").aggregate(pipeline).toArray();

  // Fetch user info for each ranked user
  const userIds = ranked.map((r) => r._id);
  const users = await db
    .collection("user")
    .find({ _id: { $in: userIds } })
    .toArray();
  const userMap = Object.fromEntries(users.map((u) => [u._id.toString(), u]));

  const userId = req.session.user.id;

  const leaderboard = ranked.map((r, i) => {
    const user = userMap[r._id.toString()];
    return {
      rank: i + 1,
      userId: r._id,
      name: user?.name || user?.phoneNumber || "User",
      nudgeCount: r.nudgeCount,
      isCurrentUser: r._id === userId,
    };
  });

  // Find current user's rank if not in top 20
  const currentUserEntry = leaderboard.find((e) => e.isCurrentUser);
  let currentUserRank = currentUserEntry?.rank ?? null;

  if (!currentUserEntry) {
    const userNudgeCount = await db
      .collection("nudges")
      .countDocuments({ userId });

    if (userNudgeCount > 0) {
      const usersAbove = await db
        .collection("nudges")
        .aggregate([
          { $group: { _id: "$userId", nudgeCount: { $sum: 1 } } },
          { $match: { nudgeCount: { $gt: userNudgeCount } } },
          { $count: "count" },
        ])
        .toArray();

      currentUserRank = (usersAbove[0]?.count ?? 0) + 1;
    }
  }

  return res.json({
    leaderboard,
    currentUser: {
      rank: currentUserRank,
      nudgeCount:
        currentUserEntry?.nudgeCount ??
        (await db.collection("nudges").countDocuments({ userId })),
    },
  });
});

export default router;
