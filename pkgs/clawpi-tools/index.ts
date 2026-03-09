import registerAudioTools from "./audio";
import registerScreenshotTools from "./screenshot";

export default function (api: any) {
  registerAudioTools(api);
  registerScreenshotTools(api);
}
