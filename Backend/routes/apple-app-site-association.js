import { Router } from "express";

const router = Router();

const defaultTeamId = "723WRFQY27";
const defaultBundleId = "jacksonmoody.Ripple";

function appId() {
  if (process.env.APPLE_APP_SITE_ASSOCIATION_APP_ID) {
    return process.env.APPLE_APP_SITE_ASSOCIATION_APP_ID;
  }

  const teamId = process.env.IOS_APP_TEAM_ID || defaultTeamId;
  const bundleId = process.env.IOS_APP_BUNDLE_ID || defaultBundleId;
  return `${teamId}.${bundleId}`;
}

function associationPayload() {
  return {
    applinks: {
      apps: [],
      details: [
        {
          appID: appId(),
          components: [
            {
              "/": "/invite/*",
              comment: "Open Ripple invite links in the iOS app",
            },
          ],
        },
      ],
    },
  };
}

router.get(
  ["/.well-known/apple-app-site-association", "/apple-app-site-association"],
  (_req, res) => {
    res
      .status(200)
      .type("application/json")
      .send(JSON.stringify(associationPayload()));
  },
);

export default router;
