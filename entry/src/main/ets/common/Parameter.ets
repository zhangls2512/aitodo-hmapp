import { promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'
import request from './Request'

interface Response {
  downloadUrl: string
}

export async function downloadParameter(context: Context) {
  const response = await request(context, '/product/getParameter', {
    type: 'chineselegalfreq'
  })
  if (response !== 'fail') {
    const res = JSON.parse(response) as Response
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      }
    })
    try {
      const response = await session.get(res.downloadUrl)
      session.close()
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return String(response)
      } else {
        await promptAction.openToast({
          message: 'HTTP 请求失败，状态码：' + response.statusCode
        })
      }
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
    }
  }
  return 'fail'
}