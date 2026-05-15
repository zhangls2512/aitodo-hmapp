import { authentication } from '@kit.AccountKit'
import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { fido2 } from '@kit.OnlineAuthenticationKit'
import { getFlushPreference } from './Preference'
import request from './Request'

interface PersonalAccountInfo {
  uid: string,
  email: string,
  endDate: number
}

interface TeamAccountInfo {
  id: string,
  path: string,
  name: string,
  teamId: string,
  teamName: string,
  authorization: string
}

export async function setPersonalAccount(accessToken: string, accountInfo: PersonalAccountInfo) {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    await appAccountManager.createAccount('personal', {
      customData: {
        uid: accountInfo.uid,
        email: accountInfo.email,
        endDate: String(accountInfo.endDate)
      }
    })
    await appAccountManager.setCredential('personal', 'accessToken', accessToken)
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function getPersonalAccountAccessToken() {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    const endDate = Number(appAccountManager.getCustomDataSync('personal', 'endDate'))
    if (endDate < Date.now() && endDate !== 0) {
      await removeAccount('personal')
      await promptAction.openToast({
        message: '登录态过期，请重新登录'
      })
      return ''
    }
    const accessToken = await appAccountManager.getCredential('personal', 'accessToken')
    return accessToken
  } catch {
    return ''
  }
}

export async function getPersonalAccountInfo(): Promise<PersonalAccountInfo> {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    const endDate = Number(appAccountManager.getCustomDataSync('personal', 'endDate'))
    if (endDate < Date.now()) {
      await removeAccount('personal')
      await promptAction.openToast({
        message: '登录态过期，请重新登录'
      })
      return {
        uid: '',
        email: '',
        endDate: 0
      }
    }
    return {
      uid: appAccountManager.getCustomDataSync('personal', 'uid'),
      email: appAccountManager.getCustomDataSync('personal', 'email'),
      endDate: endDate
    }
  } catch {
    return {
      uid: '',
      email: '',
      endDate: 0
    }
  }
}

export async function autoLoginPersonalAccount(context: Context) {
  const accessToken = await getPersonalAccountAccessToken()
  if (!accessToken) {
    const autoLoginByHuaweiAccount = getFlushPreference(context, 'commonSetting', 'autoLoginByHuaweiAccount', false)
    const autoLoginByPasskey = getFlushPreference(context, 'commonSetting', 'autoLoginByPasskey', false)
    try {
      if (autoLoginByHuaweiAccount && !autoLoginByPasskey) {
        const loginRequest = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest()
        loginRequest.forceLogin = false
        const controller = new authentication.AuthenticationController()
        const authenticationResponse: authentication.LoginWithHuaweiIDResponse =
          await controller.executeRequest(loginRequest)
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const loginResponse = await request(context, '/account/getAccessToken', {
          verifyType: 'huaweiaitodoapp',
          verifyCode: authenticationResponse.data?.authorizationCode
        })
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (loginResponse !== 'fail') {
          const accessToken = JSON.parse(loginResponse).accessToken as string
          const uid = JSON.parse(loginResponse).uid as string
          const email = JSON.parse(loginResponse).email as string
          const endDate = JSON.parse(loginResponse).endDate as number
          await setPersonalAccount(accessToken, {
            uid: uid,
            email: email,
            endDate: endDate
          })
          await promptAction.openToast({
            message: '华为账号静默登录成功'
          })
          context.eventHub.emit('refreshMe')
        }
      }
      if (autoLoginByPasskey && !autoLoginByHuaweiAccount) {
        const publicKeyAssertionCredential = await fido2.authenticate(context, {
          publicKey: {
            challenge: new util.TextEncoder().encodeInto(String(Date.now()).slice(0, -5) + '00000'),
            timeout: 100000,
            rpId: 'www.zhangls2512.cn'
          }
        })
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
        })
        const loginResponse = await request(context, '/account/getAccessToken', {
          verifyType: 'passkey',
          credentialId: new util.Base64Helper().encodeToStringSync(publicKeyAssertionCredential.rawId,
            util.Type.BASIC_URL_SAFE),
          authenticatorData: new util.Base64Helper().encodeToStringSync(
            publicKeyAssertionCredential.response.authenticatorData,
            util.Type.BASIC_URL_SAFE),
          clientDataJSON: new util.Base64Helper().encodeToStringSync(
            publicKeyAssertionCredential.response.clientDataJson,
            util.Type.BASIC_URL_SAFE),
          signature: new util.Base64Helper().encodeToStringSync(publicKeyAssertionCredential.response.signature,
            util.Type.BASIC_URL_SAFE)
        })
        netBoost.setSceneDesc({
          scene: 'login',
          sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
        })
        if (loginResponse !== 'fail') {
          const accessToken = JSON.parse(loginResponse).accessToken as string
          const uid = JSON.parse(loginResponse).uid as string
          const email = JSON.parse(loginResponse).email as string
          const endDate = JSON.parse(loginResponse).endDate as number
          await setPersonalAccount(accessToken, {
            uid: uid,
            email: email,
            endDate: endDate
          })
          await promptAction.openToast({
            message: '通行密钥静默登录成功'
          })
          context.eventHub.emit('refreshMe')
        }
      }
    } catch (err) {
      if (err.code !== 1021300004) {
        await promptAction.openToast({
          message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
        })
      }
    }
  }
}

export async function newTeamAccount(accountInfo: TeamAccountInfo) {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    await appAccountManager.createAccount(accountInfo.id, {
      customData: {
        path: accountInfo.path,
        name: accountInfo.name,
        teamId: accountInfo.teamId,
        teamName: accountInfo.teamName
      }
    })
    await appAccountManager.setCredential(accountInfo.id, 'authorization', accountInfo.authorization)
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function getTeamName(teamId: string) {
  if (!teamId) {
    return '个人'
  }
  const teamAccountList = await getTeamAccountList()
  const teamAccount = teamAccountList.find(item => item.teamId === teamId)
  if (teamAccount) {
    return teamAccount.teamName
  }
  return '未知团队'
}

export async function getTeamAccountAuthorization(teamId: string) {
  const teamAccountList = await getTeamAccountList()
  const authorization = teamAccountList.find(item => item.teamId === teamId)?.authorization
  if (authorization) {
    return authorization
  }
  return ''
}

export async function getTeamAccountList(): Promise<TeamAccountInfo[]> {
  const appAccountManager = appAccount.createAppAccountManager()
  const appAccountIds = await appAccountManager.getAccountsByOwner('com.zhangxm.aitodo')
  const appAccounts: TeamAccountInfo[] = []
  const promises = appAccountIds.map(async (item) => {
    const id = item.name
    if (id !== 'personal') {
      appAccounts.push({
        id: id,
        path: appAccountManager.getCustomDataSync(id, 'path'),
        name: appAccountManager.getCustomDataSync(id, 'name'),
        teamId: appAccountManager.getCustomDataSync(id, 'teamId'),
        teamName: appAccountManager.getCustomDataSync(id, 'teamName'),
        authorization: await appAccountManager.getCredential(id, 'authorization')
      })
    }
  })
  await Promise.all(promises)
  return appAccounts
}

export async function updateTeamAccountAuthorization(id: string, authorization: string) {
  const appAccountManager = appAccount.createAppAccountManager()
  try {
    await appAccountManager.setCredential(id, 'authorization', authorization)
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
  }
}

export async function removeAccount(id: string) {
  const appAccountManager = appAccount.createAppAccountManager()
  await appAccountManager.removeAccount(id)
}