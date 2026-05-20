import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { rcp } from '@kit.RemoteCommunicationKit'
import { getCaldavServerInfo } from './Caldavserver'
import { importTodo, TodoItem } from './Dataimport'
import { icsparse, icsstringify } from './Ics'

export async function caldavBackup(todoArray: TodoItem[]) {
  const caldavServerInfo = await getCaldavServerInfo()
  if (!caldavServerInfo.path) {
    return 'fail'
  }
  const session = rcp.createSession({
    requestConfiguration: {
      security: {
        tlsRange: {
          min: 'TlsV1.2'
        }
      }
    },
    headers: {
      'content-type': 'text/calendar',
      Authorization: 'Basic ' +
        new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(caldavServerInfo.username + ':' +
          caldavServerInfo.password))
    }
  })
  for (let i = 0; i < todoArray.length; i++) {
    const item = todoArray[i]
    const icsstring = icsstringify([item])
    try {
      const response = await session.put(caldavServerInfo.path + '/' + item.id + '.ics', icsstring)
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
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }
  session.close()
  return 'success'
}

export async function caldavGet() {
  const caldavServerInfo = await getCaldavServerInfo()
  if (!caldavServerInfo.path) {
    return 'fail'
  }
  const authorization = 'Basic ' + new util.Base64Helper().encodeToStringSync(
    new util.TextEncoder().encodeInto(caldavServerInfo.username + ':' + caldavServerInfo.password))
  const session = rcp.createSession({
    requestConfiguration: {
      security: {
        tlsRange: {
          min: 'TlsV1.2'
        }
      }
    },
    headers: {
      Authorization: authorization,
      Depth: '1'
    }
  })
  try {
    const response = await session.fetch(new rcp.Request(caldavServerInfo.path + '/', 'PROPFIND', {
      Authorization: authorization,
      Depth: '1'
    }))
    session.close()
    if (response.statusCode >= 200 && response.statusCode < 300) {
      const icsPathArray = Array.from(String(response).matchAll(/<href>(.*?)<\/href>/g))
        .map(item => item[1])
        .filter(item => item.endsWith('.ics'))
        .map(item => item.substring(item.lastIndexOf('/')))
      const todoArray: TodoItem[] = []
      const sessionb = rcp.createSession({
        requestConfiguration: {
          security: {
            tlsRange: {
              min: 'TlsV1.2'
            }
          }
        },
        headers: {
          Authorization: authorization
        }
      })
      for (let i = 0; i < icsPathArray.length; i++) {
        try {
          const response = await sessionb.get(caldavServerInfo.path + icsPathArray[i])
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
          sessionb.close()
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code
          })
          return 'fail'
        }
      }
      sessionb.close()
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
    session.close()
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return 'fail'
  }
}

export async function caldavRecovery(context: Context, conflictResolution: relationalStore.ConflictResolution) {
  const res = await caldavGet()
  if (res !== 'fail') {
    const importres = await importTodo(context, JSON.stringify({
      encrypted: false,
      data: res
    }), conflictResolution)
    return importres
  }
  return 'fail'
}

export async function caldavDelete(idArray: string[]) {
  const caldavServerInfo = await getCaldavServerInfo()
  if (!caldavServerInfo.path) {
    return 'fail'
  }
  const session = rcp.createSession({
    requestConfiguration: {
      security: {
        tlsRange: {
          min: 'TlsV1.2'
        }
      }
    },
    headers: {
      Authorization: 'Basic ' +
        new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(caldavServerInfo.username + ':' +
          caldavServerInfo.password))
    }
  })
  for (let i = 0; i < idArray.length; i++) {
    try {
      const response = await session.delete(caldavServerInfo.path + '/' + idArray[i] + '.ics')
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
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }
  session.close()
  return 'success'
}

export async function caldavDeleteAll() {
  const res = await caldavGet()
  if (res !== 'fail') {
    const idArray = res.map(item => item.id)
    const deleteres = await caldavDelete(idArray)
    return deleteres
  }
  return 'fail'
}