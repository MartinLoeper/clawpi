import registerAudioTools from "./audio";
import registerScreenshotTools from "./screenshot";
import registerScreenTools from "./screen";
import registerCanvasTools from "./canvas";

export default function (api: any) {
  registerAudioTools(api);
  registerScreenshotTools(api);
  registerScreenTools(api);
  registerCanvasTools(api);
}
