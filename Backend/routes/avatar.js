import { Router } from "express";
import multer from "multer";
import { ObjectId } from "mongodb";
import { fromNodeHeaders } from "better-auth/node";
import { auth, getDb, getAvatarBucket } from "../auth.js";

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Only image files are allowed"));
    }
  },
});

const router = Router();

// Auth middleware for routes that need it (POST/DELETE)
async function requireAuth(req, res, next) {
  const session = await auth.api.getSession({
    headers: fromNodeHeaders(req.headers),
  });
  if (!session) {
    return res.status(401).json({ error: "Not authenticated" });
  }
  req.session = session;
  next();
}

// POST /api/profile/avatar — upload profile picture
router.post("/", requireAuth, upload.single("avatar"), async (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No image file provided" });
  }

  const db = await getDb();
  const bucket = getAvatarBucket();
  const userId = req.session.user.id;

  // Delete existing avatar if any
  const user = await db.collection("user").findOne({ _id: userId });
  if (user?.avatarFileId) {
    try {
      await bucket.delete(new ObjectId(user.avatarFileId));
    } catch {
      // Old file may already be gone
    }
  }

  // Upload new avatar to GridFS
  const filename = `avatar_${userId}_${Date.now()}`;
  const uploadStream = bucket.openUploadStream(filename, {
    contentType: req.file.mimetype,
    metadata: { userId },
  });

  uploadStream.end(req.file.buffer);

  await new Promise((resolve, reject) => {
    uploadStream.on("finish", resolve);
    uploadStream.on("error", reject);
  });

  const fileId = uploadStream.id;

  // Store the GridFS file ID on the user document
  await db
    .collection("user")
    .updateOne({ _id: userId }, { $set: { avatarFileId: fileId.toString() } });

  const baseURL = process.env.BASE_URL || `http://localhost:${process.env.PORT || 3005}`;

  return res.json({
    success: true,
    avatarUrl: `${baseURL}/api/profile/avatar/${userId}`,
  });
});

// GET /api/profile/avatar/:userId — serve avatar image (public, no auth)
router.get("/:userId", async (req, res) => {
  const db = await getDb();
  const user = await db.collection("user").findOne({ _id: req.params.userId });

  if (!user?.avatarFileId) {
    return res.status(404).json({ error: "No avatar found" });
  }

  const bucket = getAvatarBucket();

  try {
    const fileId = new ObjectId(user.avatarFileId);

    const files = await bucket.find({ _id: fileId }).toArray();
    if (files.length === 0) {
      return res.status(404).json({ error: "Avatar file not found" });
    }

    const file = files[0];
    res.set("Content-Type", file.contentType || "image/jpeg");
    res.set("Cache-Control", "public, max-age=3600");

    const downloadStream = bucket.openDownloadStream(fileId);
    downloadStream.pipe(res);
  } catch {
    return res.status(404).json({ error: "Avatar not found" });
  }
});

// DELETE /api/profile/avatar — remove avatar
router.delete("/", requireAuth, async (req, res) => {
  const db = await getDb();
  const userId = req.session.user.id;
  const user = await db.collection("user").findOne({ _id: userId });

  if (!user?.avatarFileId) {
    return res.json({ success: true });
  }

  const bucket = getAvatarBucket();
  try {
    await bucket.delete(new ObjectId(user.avatarFileId));
  } catch {
    // File may already be gone
  }

  await db
    .collection("user")
    .updateOne({ _id: userId }, { $unset: { avatarFileId: "" } });

  return res.json({ success: true });
});

export default router;
