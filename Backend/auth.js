import "dotenv/config";
import { betterAuth } from "better-auth";
import { mongodbAdapter } from "better-auth/adapters/mongodb";
import { phoneNumber, bearer } from "better-auth/plugins";
import { MongoClient, GridFSBucket } from "mongodb";
import twilio from "twilio";

let cachedClient = null;

async function getMongoClient() {
  if (cachedClient) return cachedClient;
  const client = new MongoClient(process.env.MONGODB_URI);
  await client.connect();
  cachedClient = client;
  return client;
}

const client = await getMongoClient();
const db = client.db();

export async function getDb() {
  const c = await getMongoClient();
  return c.db();
}

export function getAvatarBucket() {
  return new GridFSBucket(db, { bucketName: "avatars" });
}

// Ensure indexes for nudges collection
db.collection("nudges")
  .createIndex({ userId: 1, createdAt: -1 })
  .catch(() => {});

const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);
const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

export const auth = betterAuth({
  baseURL: process.env.BASE_URL || "https://sway-ripple-backend.vercel.app",
  secret: process.env.BETTER_AUTH_SECRET,
  database: mongodbAdapter(db, { client }),
  plugins: [
    bearer(),
    phoneNumber({
      sendOTP: async ({ phoneNumber }, ctx) => {
        const verification = await twilioClient.verify.v2
          .services(verifyServiceSid)
          .verifications.create({ to: phoneNumber, channel: "sms" });
        console.log(`[OTP] Verification sent to ${phoneNumber}: ${verification.status}`);
      },
      verifyOTP: async ({ phoneNumber, code }, ctx) => {
        const check = await twilioClient.verify.v2
          .services(verifyServiceSid)
          .verificationChecks.create({ to: phoneNumber, code });
        return check.status === "approved";
      },
      signUpOnVerification: {
        getTempEmail: (phone) => {
          const cleaned = phone.replace(/\D/g, "");
          return `${cleaned}@ripple.app`;
        },
        getTempName: (phone) => phone,
      },
    }),
  ],
  trustedOrigins: (origin) => true,
});
