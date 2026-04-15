import "dotenv/config";
import { betterAuth } from "better-auth";
import { mongodbAdapter } from "better-auth/adapters/mongodb";
import { phoneNumber } from "better-auth/plugins";
import { MongoClient } from "mongodb";
import twilio from "twilio";

const client = new MongoClient(process.env.MONGODB_URI);
const db = client.db();

const twilioClient = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);
const verifyServiceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

export const auth = betterAuth({
  baseURL: process.env.BASE_URL || "http://localhost:3005",
  secret: process.env.BETTER_AUTH_SECRET,
  database: mongodbAdapter(db, { client }),
  plugins: [
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
  trustedOrigins: ["ripple://"],
});
