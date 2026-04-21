import { Router } from "express";
import { ObjectId } from "mongodb";
import { getDb } from "../auth.js";
import { computeUserScore } from "./stats.js";

const router = Router();

// GET /api/leaderboard — ranked users by score
router.get("/", async (req, res) => {
  const db = await getDb();
  const userId = req.session.user.id;

  // Get all users who have at least one rally
  const activeUserIds = await db
    .collection("rallies")
    .aggregate([
      { $group: { _id: "$userId" } },
    ])
    .toArray();

  // Compute scores for all active users
  const scoredUsers = await Promise.all(
    activeUserIds.map(async (entry) => {
      const score = await computeUserScore(db, entry._id);
      return { userId: entry._id, score: score.score };
    })
  );

  // Sort by score descending and take top 20
  scoredUsers.sort((a, b) => b.score - a.score);
  const top20 = scoredUsers.slice(0, 20);

  // Fetch user info
  const userIds = top20.map((r) => r.userId);
  const users = await db
    .collection("user")
    .find({ _id: { $in: userIds.map((id) => new ObjectId(id)) } })
    .toArray();
  const userMap = Object.fromEntries(users.map((u) => [u._id.toString(), u]));

  const baseURL =
    process.env.BASE_URL || `http://localhost:${process.env.PORT || 3005}`;

  const leaderboard = top20.map((r, i) => {
    const user = userMap[r.userId];
    const hasName = user?.name && !user.name.startsWith("+");
    return {
      rank: i + 1,
      userId: r.userId,
      name: hasName ? user.name : user?.phoneNumber || "User",
      score: r.score,
      isCurrentUser: r.userId === userId,
      avatarUrl: user?.avatarFileId
        ? `${baseURL}/api/profile/avatar/${user._id.toString()}`
        : null,
    };
  });

  // Current user's score
  const currentUserEntry = leaderboard.find((e) => e.isCurrentUser);
  let currentUserRank = currentUserEntry?.rank ?? null;
  let currentUserScore = currentUserEntry?.score ?? 0;

  if (!currentUserEntry) {
    const userScore = await computeUserScore(db, userId);
    currentUserScore = userScore.score;

    if (currentUserScore > 0) {
      const usersAbove = scoredUsers.filter(
        (u) => u.score > currentUserScore
      ).length;
      currentUserRank = usersAbove + 1;
    }
  }

  return res.json({
    leaderboard,
    currentUser: {
      rank: currentUserRank,
      score: currentUserScore,
    },
  });
});

export default router;
