import { promptAction } from '@kit.ArkUI'
import { deviceCertificate } from '@kit.DeviceSecurityKit'

export default async function getDeviceToken() {
  try {
    const deviceToken = await deviceCertificate.getDeviceToken()
    return deviceToken
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return ''
  }
}