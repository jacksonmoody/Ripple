import { Router } from "express";
import { auth } from "./auth.js";
import { fromNodeHeaders } from "better-auth/node";

const router = Router();

const TS_ENDPOINT = "https://api.targetsmart.com/service/smartmatch";
const TS_POLL_ENDPOINT = "https://api.targetsmart.com/service/smartmatch/poll";
const POLL_INTERVAL_MS = 30_000;
const MAX_POLL_ATTEMPTS = 20;

// POST /api/smartmatch
// Body: { phones: [{ id: "contact-id", phone: "1234567890" }, ...] }
// Returns: { results: { "contact-id": { phone, address, city, state, zip }, ... } }
router.post("/", async (req, res) => {
  // Require authentication
  const session = await auth.api.getSession({
    headers: fromNodeHeaders(req.headers),
  });
  if (!session) {
    return res.status(401).json({ error: "Not authenticated" });
  }

  const apiKey = process.env.TS_API_KEY;
  if (!apiKey) {
    return res.status(500).json({ error: "SmartMatch API key not configured" });
  }

  const { phones } = req.body;
  if (!Array.isArray(phones) || phones.length === 0) {
    return res.status(400).json({ error: "phones array is required" });
  }

  try {
    const filename = `ripple_${Date.now()}`;
    const csv = buildCSV(phones);

    // Step 1: Register and get presigned upload URL
    const uploadUrl = await register(filename, apiKey);

    // Step 2: Upload CSV
    await uploadCSV(csv, uploadUrl);

    // Step 3: Poll for results
    const resultsCsv = await pollForResults(filename, apiKey);

    // Step 4: Parse and return
    const results = parseResults(resultsCsv);
    return res.json({ results });
  } catch (err) {
    console.error("[SmartMatch] Error:", err.message);
    return res.status(502).json({ error: err.message });
  }
});

function buildCSV(phones) {
  const header = "matchback_id,phone";
  const rows = phones.map(({ id, phone }) => {
    const digits = phone.replace(/\D/g, "");
    return `${id},${digits}`;
  });
  return [header, ...rows].join("\n");
}

async function register(filename, apiKey) {
  const url = `${TS_ENDPOINT}?filename=${encodeURIComponent(filename)}`;
  const resp = await fetch(url, {
    method: "GET",
    headers: { "x-api-key": apiKey },
  });

  const data = await resp.json();
  if (data.error) {
    throw new Error(`Registration failed: ${data.error}`);
  }
  if (!data.url) {
    throw new Error("No upload URL returned from SmartMatch");
  }
  return data.url;
}

async function uploadCSV(csv, uploadUrl) {
  const resp = await fetch(uploadUrl, {
    method: "PUT",
    headers: { "Content-Type": "" },
    body: csv,
  });

  if (!resp.ok) {
    throw new Error(`CSV upload failed with status ${resp.status}`);
  }
}

async function pollForResults(filename, apiKey) {
  const url = `${TS_POLL_ENDPOINT}?filename=${encodeURIComponent(filename)}`;

  for (let i = 0; i < MAX_POLL_ATTEMPTS; i++) {
    await sleep(POLL_INTERVAL_MS);

    const resp = await fetch(url, {
      method: "GET",
      headers: { "x-api-key": apiKey },
    });

    const data = await resp.json();
    if (data.url) {
      const dlResp = await fetch(data.url);
      if (!dlResp.ok) {
        throw new Error("Failed to download SmartMatch results");
      }
      return await dlResp.text();
    }
  }

  throw new Error("SmartMatch poll timed out");
}

function parseResults(csv) {
  const lines = csv.split("\n").filter((l) => l.trim());
  if (lines.length < 2) return {};

  const header = parseCSVLine(lines[0]).map((h) => h.toLowerCase().trim());

  const phoneIdx = header.indexOf("phone");
  const matchbackIdx = header.indexOf("matchback_id");
  const addressIdx = findFirst(header, [
    "vb.regaddress",
    "address1",
    "vb.regaddr",
  ]);
  const cityIdx = findFirst(header, ["vb.regcity", "city"]);
  const stateIdx = findFirst(header, [
    "vb.regstate",
    "vb.regstatecode",
    "state",
  ]);
  const zipIdx = findFirst(header, ["vb.regzip", "zip"]);

  const results = {};

  for (let i = 1; i < lines.length; i++) {
    const fields = parseCSVLine(lines[i]);
    const phone = safeGet(fields, phoneIdx) || "";
    const key = safeGet(fields, matchbackIdx) || phone;
    if (!key) continue;

    const state = safeGet(fields, stateIdx);
    if (!state) continue;

    results[key] = {
      phone,
      address: safeGet(fields, addressIdx),
      city: safeGet(fields, cityIdx),
      state,
      zip: safeGet(fields, zipIdx),
    };
  }

  return results;
}

function findFirst(header, candidates) {
  for (const c of candidates) {
    const idx = header.indexOf(c);
    if (idx !== -1) return idx;
  }
  return -1;
}

function safeGet(arr, idx) {
  if (idx < 0 || idx >= arr.length) return null;
  const val = arr[idx].trim();
  return val || null;
}

function parseCSVLine(line) {
  const fields = [];
  let current = "";
  let inQuotes = false;

  for (const ch of line) {
    if (ch === '"') {
      inQuotes = !inQuotes;
    } else if (ch === "," && !inQuotes) {
      fields.push(current);
      current = "";
    } else {
      current += ch;
    }
  }
  fields.push(current);
  return fields;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export default router;
