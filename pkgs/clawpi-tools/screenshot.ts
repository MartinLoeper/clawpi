import { Type } from "@sinclair/typebox";
import { readFile, unlink } from "node:fs/promises";
import { randomBytes } from "node:crypto";
import http from "node:http";
import { runWayland, text, image } from "./helpers";

export default function (api: any) {
  // ── Full compositor screenshot (grim) ──────────────────────────────
  api.registerTool({
    name: "screenshot_display",
    description:
      "Capture a screenshot of the entire Wayland display using grim. " +
      "This captures everything visible on the physical screen — the " +
      "Chromium kiosk window AND any Eww overlays on top. Use this to " +
      "see exactly what the user sees on the monitor. Returns a PNG image.",
    parameters: Type.Object({}),
    async execute() {
      const tmpFile = `/tmp/clawpi-grim-${randomBytes(4).toString("hex")}.png`;
      try {
        await runWayland("grim", [tmpFile]);
        const data = await readFile(tmpFile);
        return image(data.toString("base64"), "image/png");
      } finally {
        await unlink(tmpFile).catch(() => {});
      }
    },
  });

  // ── Browser viewport screenshot (CDP) ──────────────────────────────
  api.registerTool({
    name: "screenshot_browser",
    description:
      "Capture a screenshot of the Chromium browser viewport via CDP " +
      "(Chrome DevTools Protocol). This captures only the web page " +
      "content rendered inside the browser — Eww overlays and compositor " +
      "elements are NOT included. Use this when you need a clean capture " +
      "of just the web content (e.g. a dashboard, a specific page). " +
      "Returns a PNG image.",
    parameters: Type.Object({
      quality: Type.Optional(
        Type.Number({
          description:
            "JPEG quality 0-100 (only used if format is jpeg). Ignored for PNG.",
          minimum: 0,
          maximum: 100,
        }),
      ),
      format: Type.Optional(
        Type.Union([Type.Literal("png"), Type.Literal("jpeg")], {
          description: 'Image format: "png" (default) or "jpeg".',
        }),
      ),
    }),
    async execute(
      _id: string,
      params: { quality?: number; format?: "png" | "jpeg" },
    ) {
      const fmt = params.format ?? "png";
      const cdpUrl = "http://127.0.0.1:9222";

      // Fetch first page target from CDP
      const targets: any[] = await new Promise((resolve, reject) => {
        http
          .get(`${cdpUrl}/json`, (res) => {
            let body = "";
            res.on("data", (chunk: string) => (body += chunk));
            res.on("end", () => {
              try {
                resolve(JSON.parse(body));
              } catch (e) {
                reject(e);
              }
            });
          })
          .on("error", reject);
      });

      const page = targets.find((t: any) => t.type === "page");
      if (!page) {
        return text("Error: No browser page found on CDP port 9222.");
      }

      // Connect to page WebSocket and capture screenshot
      const WebSocket = (await import("ws")).default;
      const ws = new WebSocket(page.webSocketDebuggerUrl);

      const result: string = await new Promise((resolve, reject) => {
        ws.on("open", () => {
          const captureParams: any = { format: fmt };
          if (fmt === "jpeg" && params.quality != null) {
            captureParams.quality = params.quality;
          }
          ws.send(
            JSON.stringify({
              id: 1,
              method: "Page.captureScreenshot",
              params: captureParams,
            }),
          );
        });
        ws.on("message", (data: any) => {
          const resp = JSON.parse(data.toString());
          if (resp.id === 1) {
            ws.close();
            if (resp.error) {
              reject(new Error(resp.error.message));
            } else {
              resolve(resp.result.data);
            }
          }
        });
        ws.on("error", reject);
      });

      const mimeType = fmt === "jpeg" ? "image/jpeg" : "image/png";
      return image(result, mimeType);
    },
  });
}
