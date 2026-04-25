import { promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getFlushPreference } from './Preference'

interface ErrorResponse {
  errCode: number,
  errMsg: string,
  errFix: string
}

export default async function request(context: Context, path: string, body: rcp.RequestContent) {
  const allService = getFlushPreference(context, 'commonSetting', 'allService', true)
  if (!allService) {
    context.eventHub.emit('dialog', '全量模式未开启',
      '全量模式未开启，无法使用在线功能。如需使用在线功能，请前往“我的”>“设置”>“更多”>“应用服务模式”，开启全量模式。')
    return 'fail'
  }
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
    const response = await session.post('https://api.zhangls2512.cn' + path, body)
    session.close()
    if (response.statusCode >= 200 && response.statusCode < 300) {
      const res = response.toJSON() as ErrorResponse
      if (res.errCode === 0) {
        return JSON.stringify(res)
      }
      context.eventHub.emit('dialog', '接口调用失败',
        '错误码：' + res.errCode + '\n错误信息：' + res.errMsg + '\n修复方法：' + res.errFix)
      return 'fail'
    } else {
      await promptAction.openToast({
        message: '请求失败，错误码：' + response.statusCode
      })
      return 'fail'
    }
  } catch (err) {
    session.close()
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}