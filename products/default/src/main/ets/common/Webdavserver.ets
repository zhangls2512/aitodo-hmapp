import { promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'

interface WebdavServerInfo {
  path: string,
  username: string,
  password: string
}

export async function getWebdavServerInfo(): Promise<WebdavServerInfo> {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    const path = appAccountManager.getCustomDataSync('webdavserver', 'path')
    const username = appAccountManager.getCustomDataSync('webdavserver', 'username')
    const password = await appAccountManager.getCredential('webdavserver', 'password')
    return {
      path: path,
      username: username,
      password: password
    }
  } catch {
    return {
      path: '',
      username: '',
      password: ''
    }
  }
}

export async function setWebdavServer(webdavServerInfo: WebdavServerInfo) {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    await appAccountManager.createAccount('webdavserver', {
      customData: {
        path: webdavServerInfo.path,
        username: webdavServerInfo.username
      }
    })
    await appAccountManager.setCredential('webdavserver', 'password', webdavServerInfo.password)
    return 'success'
  } catch (err) {
    if (err.code !== 12300004) {
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
    if (err.code === 12300004) {
      await appAccountManager.setCustomData('webdavserver', 'path', webdavServerInfo.path)
      await appAccountManager.setCustomData('webdavserver', 'username', webdavServerInfo.username)
      await appAccountManager.setCredential('webdavserver', 'password', webdavServerInfo.password)
    }
    return 'success'
  }
}