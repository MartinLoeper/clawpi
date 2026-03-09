import { Type } from "@sinclair/typebox";
import { run, text } from "./helpers";

export default function (api: any) {
  api.registerTool({
    name: "audio_status",
    description:
      "List all PipeWire/WirePlumber audio devices, sinks, and sources. " +
      "Shows sink IDs needed for audio_set_default_sink.",
    parameters: Type.Object({}),
    async execute() {
      const { stdout } = await run("wpctl", ["status"]);
      return text(stdout);
    },
  });

  api.registerTool({
    name: "audio_get_volume",
    description:
      "Get the current volume level of the default audio sink. " +
      "Returns a value between 0.0 and 1.0 (plus mute status).",
    parameters: Type.Object({}),
    async execute() {
      const { stdout } = await run("wpctl", [
        "get-volume",
        "@DEFAULT_AUDIO_SINK@",
      ]);
      return text(stdout.trim());
    },
  });

  api.registerTool({
    name: "audio_set_volume",
    description:
      "Set the volume of the default audio sink. " +
      "Accepts a value between 0.0 (mute) and 1.0 (maximum).",
    parameters: Type.Object({
      level: Type.Number({
        description: "Volume level from 0.0 to 1.0",
        minimum: 0,
        maximum: 1,
      }),
    }),
    async execute(_id: string, params: { level: number }) {
      await run("wpctl", [
        "set-volume",
        "@DEFAULT_AUDIO_SINK@",
        String(params.level),
      ]);
      const { stdout } = await run("wpctl", [
        "get-volume",
        "@DEFAULT_AUDIO_SINK@",
      ]);
      return text(`Volume set. ${stdout.trim()}`);
    },
  });

  api.registerTool({
    name: "audio_test_tone",
    description:
      "Play a short test tone through the default audio sink to verify " +
      "audio output is working. Plays a 440 Hz sine wave for ~3 seconds.",
    parameters: Type.Object({
      frequency: Type.Optional(
        Type.Number({
          description: "Tone frequency in Hz (default: 440)",
          minimum: 20,
          maximum: 20000,
        }),
      ),
      duration: Type.Optional(
        Type.Number({
          description: "Duration in seconds (default: 3)",
          minimum: 1,
          maximum: 30,
        }),
      ),
    }),
    async execute(
      _id: string,
      params: { frequency?: number; duration?: number },
    ) {
      const freq = String(params.frequency ?? 440);
      const dur = String(params.duration ?? 3);
      await run("speaker-test", [
        "-D", "pipewire",
        "-t", "sine",
        "-f", freq,
        "-c", "2",
        "-l", "1",
        "-p", dur,
      ]);
      return text(`Test tone played (${freq} Hz, ${dur}s).`);
    },
  });

  api.registerTool({
    name: "audio_set_default_sink",
    description:
      "Set the default audio output sink by its WirePlumber sink ID. " +
      "Use audio_status first to find available sink IDs.",
    parameters: Type.Object({
      sink_id: Type.Number({
        description:
          "WirePlumber sink ID (from audio_status output, e.g. 54 for USB speaker, 73 for HDMI)",
      }),
    }),
    async execute(_id: string, params: { sink_id: number }) {
      await run("wpctl", ["set-default", String(params.sink_id)]);
      return text(`Default sink set to ${params.sink_id}.`);
    },
  });
}
