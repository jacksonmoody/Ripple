import { Router } from "express";
import { ObjectId } from "mongodb";
import { getDb } from "../auth.js";

const router = Router();

// GET /api/leaderboard — ranked users by rally count
router.get("/", async (req, res) => {
  const db = await getDb();

  const pipeline = [
    { $group: { _id: "$userId", rallyCount: { $sum: 1 } } },
    { $sort: { rallyCount: -1 } },
    { $limit: 20 },
  ];

  const ranked = await db.collection("rallies").aggregate(pipeline).toArray();

  // Fetch user info for each ranked user
  const userIds = ranked.map((r) => r._id);
  const users = await db
    .collection("user")
    .find({ _id: { $in: userIds.map((id) => new ObjectId(id)) } })
    .toArray();
  const userMap = Object.fromEntries(users.map((u) => [u._id.toString(), u]));

  const userId = req.session.user.id;

  const baseURL = process.env.BASE_URL;
  const leaderboard = ranked.map((r, i) => {
    const user = userMap[r._id.toString()];
    const hasName = user?.name && !user.name.startsWith("+");
    return {
      rank: i + 1,
      userId: r._id,
      name: hasName ? user.name : (user?.phoneNumber || "User"),
      rallyCount: r.rallyCount,
      isCurrentUser: r._id === userId,
      avatarUrl: user?.avatarFileId
        ? `${baseURL}/api/profile/avatar/${user._id.toString()}`
        : null,
    };
  });

  // Find current user's rank if not in top 20
  const currentUserEntry = leaderboard.find((e) => e.isCurrentUser);
  let currentUserRank = currentUserEntry?.rank ?? null;

  if (!currentUserEntry) {
    const userRallyCount = await db
      .collection("rallies")
      .countDocuments({ userId });

    if (userRallyCount > 0) {
      const usersAbove = await db
        .collection("rallies")
        .aggregate([
          { $group: { _id: "$userId", rallyCount: { $sum: 1 } } },
          { $match: { rallyCount: { $gt: userRallyCount } } },
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
      rallyCount:
        currentUserEntry?.rallyCount ??
        (await db.collection("rallies").countDocuments({ userId })),
    },
  });
});

export default router;
