import { promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'

interface CaldavServerInfo {
  path: string,
  username: string,
  password: string
}

let globalCaldavServerInfo: CaldavServerInfo | undefined = undefined

export async function getCaldavServerInfo(): Promise<CaldavServerInfo> {
  if (!globalCaldavServerInfo) {
    const appAccountManager = appAccount.createAppAccountManager()
    try {
      const path = appAccountManager.getCustomDataSync('caldavserver', 'path')
      const username = appAccountManager.getCustomDataSync('caldavserver', 'username')
      const password = await appAccountManager.getCredential('caldavserver', 'password')
      globalCaldavServerInfo = {
        path: path,
        username: username,
        password: password
      }
    } catch {
      globalCaldavServerInfo = {
        path: '',
        username: '',
        password: ''
      }
    }
  }
  return globalCaldavServerInfo
}

export async function setCaldavServer(caldavServerInfo: CaldavServerInfo) {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    await appAccountManager.createAccount('caldavserver', {
      customData: {
        path: caldavServerInfo.path,
        username: caldavServerInfo.username
      }
    })
    await appAccountManager.setCredential('caldavserver', 'password', caldavServerInfo.password)
    globalCaldavServerInfo = caldavServerInfo
    return 'success'
  } catch (err) {
    if (err.code !== 12300004) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
    if (err.code === 12300004) {
      await appAccountManager.setCustomData('caldavserver', 'path', caldavServerInfo.path)
      await appAccountManager.setCustomData('caldavserver', 'username', caldavServerInfo.username)
      await appAccountManager.setCredential('caldavserver', 'password', caldavServerInfo.password)
      globalCaldavServerInfo = caldavServerInfo
    }
    return 'success'
  }
}