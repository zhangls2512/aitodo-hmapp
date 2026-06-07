import { promptAction } from '@kit.ArkUI'
import { developerRequest, globalDefaultSession } from './Request'

interface Response {
  downloadUrl: string
}

export async function downloadParameter(context: Context) {
  const response = await developerRequest(context, '/product/getParameter', {
    type: 'chineselegalfreq'
  })
  if (response !== 'fail') {
    const res = JSON.parse(response) as Response
    try {
      const response = await globalDefaultSession.get(res.downloadUrl)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return String(response)
      } else {
        await promptAction.openToast({
          message: 'HTTP 请求失败，状态码：' + response.statusCode
        })
      }
    } catch (err) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
      })
    }
  }
  return 'fail'
}