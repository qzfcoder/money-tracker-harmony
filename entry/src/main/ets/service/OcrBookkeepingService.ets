import photoAccessHelper from '@ohos.file.photoAccessHelper';
import image from '@ohos.multimedia.image';
import { textRecognition } from '@kit.CoreVisionKit';
import { fileIo } from '@kit.CoreFileKit';
import { ToastUtil } from '../utils/ToastUtil';

export interface OcrBookkeepingResult {
  text: string;
  uri: string;
}

export class OcrBookkeepingService {
  static async pickScreenshotAndRecognize(): Promise<OcrBookkeepingResult | null> {
    const picker = new photoAccessHelper.PhotoViewPicker();
    const options = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = 1;
    const selectResult = await picker.select(options);
    if (!selectResult || !selectResult.photoUris || selectResult.photoUris.length === 0) {
      return null;
    }
    const uri = selectResult.photoUris[0];
    return await OcrBookkeepingService.recognizeUri(uri);
  }

  private static async recognizeUri(uri: string): Promise<OcrBookkeepingResult> {
    try {
      return await OcrBookkeepingService.recognizeImageSource(image.createImageSource(uri), uri);
    } catch (error) {
      return await OcrBookkeepingService.recognizeUriByFd(uri);
    }
  }

  private static async recognizeUriByFd(uri: string): Promise<OcrBookkeepingResult> {
    let file: fileIo.File | null = null;
    try {
      file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      return await OcrBookkeepingService.recognizeImageSource(image.createImageSource(file.fd), uri);
    } catch (error) {
      throw new Error(`图片读取失败，请确认截图已保存到相册：${ToastUtil.error(error)}`);
    } finally {
      if (file) {
        try {
          fileIo.closeSync(file);
        } catch (error) {
        }
      }
    }
  }

  private static async recognizeImageSource(source: image.ImageSource, uri: string): Promise<OcrBookkeepingResult> {
    if (!source) {
      throw new Error('图片源创建失败');
    }
    let pixelMap: image.PixelMap | null = null;
    try {
      pixelMap = await source.createPixelMap();
      return await OcrBookkeepingService.recognizePixelMap(pixelMap, uri);
    } finally {
      try {
        await source.release();
      } catch (error) {
      }
    }
  }

  private static async recognizePixelMap(pixelMap: image.PixelMap, uri: string): Promise<OcrBookkeepingResult> {
    try {
      const ready = await textRecognition.init();
      if (!ready) {
        throw new Error('OCR 服务初始化失败，当前云调试设备可能不支持本机文字识别');
      }
      const result = await OcrBookkeepingService.recognizeTextSafely(pixelMap);
      return {
        text: result.value || '',
        uri
      };
    } finally {
      try {
        await textRecognition.release();
      } catch (error) {
      }
      try {
        await pixelMap.release();
      } catch (error) {
      }
    }
  }

  private static async recognizeTextSafely(pixelMap: image.PixelMap): Promise<textRecognition.TextRecognitionResult> {
    try {
      return await textRecognition.recognizeText({ pixelMap }, { isDirectionDetectionSupported: true });
    } catch (error) {
      try {
        return await textRecognition.recognizeText({ pixelMap });
      } catch (retryError) {
        throw new Error(`OCR 引擎识别失败：${ToastUtil.error(retryError)}`);
      }
    }
  }
}
