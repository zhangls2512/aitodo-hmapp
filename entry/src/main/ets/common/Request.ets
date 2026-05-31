import { promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getTeamAccountInfo } from './Account'
import { getFlushPreference } from './Preference'

interface DeveloperErrorResponse {
  errCode: number,
  errMsg: string,
  errFix: string
}

interface TeamErrorResponse {
  code: number,
  msg: string
}

export const globalDefaultSession = rcp.createSession({
  requestConfiguration: {
    security: {
      tlsRange: {
        min: 'TlsV1.2'
      }
    }
  }
})

export async function developerRequest(context: Context, path: string, body: rcp.RequestContent) {
  const allService = getFlushPreference(context, 'commonSetting', 'allService', true)
  if (!allService) {
    context.eventHub.emit('dialog', '全量模式未开启',
      '全量模式未开启，无法使用在线功能。如需使用在线功能，请前往“我的”>“设置”>“更多”>“应用服务模式”，开启全量模式。')
    return 'fail'
  }
  try {
    const response = await globalDefaultSession.post('https://api.zhangls2512.cn' + path, body)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      const res = response.toJSON() as DeveloperErrorResponse
      if (res.errCode === 0) {
        return JSON.stringify(res)
      }
      context.eventHub.emit('dialog', '接口调用失败',
        '错误码：' + res.errCode + '\n错误信息：' + res.errMsg + '\n修复方法：' + res.errFix)
      return 'fail'
    } else {
      await promptAction.openToast({
        message: 'HTTP 请求失败，状态码：' + response.statusCode
      })
      return 'fail'
    }
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}

export async function teamRequest(context: Context, teamId: string, path: string, body?: rcp.RequestContent,
  basePath = '',
  authorization = '') {
  try {
    const teamAccountInfo = await getTeamAccountInfo(teamId)
    const response =
      await globalDefaultSession.fetch(
        new rcp.Request((basePath ? basePath : teamAccountInfo.path) + '/todoteam' + path, 'POST', {
          Authorization: authorization ? authorization : teamAccountInfo.authorization
        }, body))
    if (response.statusCode >= 200 && response.statusCode < 300) {
      const res = response.toJSON() as TeamErrorResponse
      if (res.code === 0) {
        return JSON.stringify(res)
      }
      context.eventHub.emit('dialog', '接口调用失败', '错误码：' + res.code + '\n错误信息：' + res.msg)
      return 'fail'
    } else {
      await promptAction.openToast({
        message: 'HTTP 请求失败，状态码：' + response.statusCode
      })
      return 'fail'
    }
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}