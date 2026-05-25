import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getCaldavServerInfo } from './Caldavserver'
import { importTodo, TodoItem } from './Dataimport'
import { icsparse, icsstringify } from './Ics'
import { globalDefaultSession } from './Request'

export async function caldavBackup(todoArray: TodoItem[]) {
  const caldavServerInfo = await getCaldavServerInfo()
  if (!caldavServerInfo.path) {
    return 'fail'
  }
  for (let i = 0; i < todoArray.length; i++) {
    const item = todoArray[i]
    const icsstring = icsstringify([item])
    try {
      const response =
        await globalDefaultSession.fetch(new rcp.Request(caldavServerInfo.path + '/' + item.id + '.ics', 'PUT', {
          'content-type': 'text/calendar',
          Authorization: 'Basic ' + new util.Base64Helper().encodeToStringSync(
            new util.TextEncoder().encodeInto(caldavServerInfo.username + ':' + caldavServerInfo.password))
        }, icsstring))
      if (response.statusCode < 200 || response.statusCode >= 300) {
        const statusCodeMap: Record<number, string> = {
          401: '账号密码错误',
          403: '备份目录不存在或无权限'
        }
        const reason = statusCodeMap[response.statusCode]
        if (reason) {
          await promptAction.openToast({
            message: '备份失败，原因：' + reason
          })
          return 'fail'
        }
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
  return 'success'
}

export async function caldavGet() {
  const caldavServerInfo = await getCaldavServerInfo()
  if (!caldavServerInfo.path) {
    return 'fail'
  }
  const authorization = 'Basic ' + new util.Base64Helper().encodeToStringSync(
    new util.TextEncoder().encodeInto(caldavServerInfo.username + ':' + caldavServerInfo.password))
  try {
    const response = await globalDefaultSession.fetch(new rcp.Request(caldavServerInfo.path + '/', 'PROPFIND', {
      Authorization: authorization,
      Depth: '1'
    }))
    if (response.statusCode >= 200 && response.statusCode < 300) {
      const icsPathArray = Array.from(String(response).matchAll(/<href>(.*?)<\/href>/g))
        .map(item => item[1])
        .filter(item => item.endsWith('.ics'))
        .map(item => item.substring(item.lastIndexOf('/')))
      const todoArray: TodoItem[] = []
      for (let i = 0; i < icsPathArray.length; i++) {
        try {
          const response =
            await globalDefaultSession.fetch(new rcp.Request(caldavServerInfo.path + icsPathArray[i], 'GET', {
              Authorization: authorization
            }))
          if (response.statusCode >= 200 && response.statusCode < 300) {
            const icsstring = String(response)
            if (!icsstring.includes('\r\nPRODID:') ||
              icsstring.includes('\r\nPRODID:-//xm2512//com.zhangxm.aitodo//CN\r\n')) {
              todoArray.push(icsparse(icsstring)[0])
            }
          } else {
            const statusCodeMap: Record<number, string> = {
              401: '账号密码错误',
              403: '备份目录不存在或无权限'
            }
            const reason = statusCodeMap[response.statusCode]
            if (reason) {
              await promptAction.openToast({
                message: '请求失败，原因：' + reason
              })
              return 'fail'
            }
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
      return todoArray
    } else {
      const statusCodeMap: Record<number, string> = {
        401: '账号密码错误',
        403: '备份目录不存在或无权限'
      }
      const reason = statusCodeMap[response.statusCode]
      if (reason) {
        await promptAction.openToast({
          message: '请求失败，原因：' + reason
        })
        return 'fail'
      }
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

export async function caldavRecovery(context: Context, conflictResolution: relationalStore.ConflictResolution) {
  const res = await caldavGet()
  if (res !== 'fail') {
    return await importTodo(context, JSON.stringify({
      encrypted: false,
      data: res
    }), conflictResolution)
  }
  return 'fail'
}

export async function caldavDelete(idArray: string[]) {
  const caldavServerInfo = await getCaldavServerInfo()
  if (!caldavServerInfo.path) {
    return 'fail'
  }
  for (let i = 0; i < idArray.length; i++) {
    try {
      const response =
        await globalDefaultSession.fetch(new rcp.Request(caldavServerInfo.path + '/' + idArray[i] + '.ics', 'DELETE', {
          Authorization: 'Basic ' + new util.Base64Helper().encodeToStringSync(
            new util.TextEncoder().encodeInto(caldavServerInfo.username + ':' + caldavServerInfo.password))
        }))
      if ((response.statusCode < 200 || response.statusCode >= 300) && response.statusCode !== 404) {
        const statusCodeMap: Record<number, string> = {
          401: '账号密码错误',
          403: '备份目录不存在或无权限'
        }
        const reason = statusCodeMap[response.statusCode]
        if (reason) {
          await promptAction.openToast({
            message: '备份失败，原因：' + reason
          })
          return 'fail'
        }
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
  return 'success'
}

export async function caldavDeleteAll() {
  const res = await caldavGet()
  if (res !== 'fail') {
    const idArray = res.map(item => item.id)
    return await caldavDelete(idArray)
  }
  return 'fail'
}