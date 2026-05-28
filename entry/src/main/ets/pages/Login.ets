import { common } from '@kit.AbilityKit'
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit'
import { privacyManager } from '@kit.AppGalleryKit'
import { util } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { netBoost } from '@kit.NetworkBoostKit'
import { fido2 } from '@kit.OnlineAuthenticationKit'
import { setPersonalAccount } from '../common/Account'
import openLink from '../common/Openlink'
import { developerRequest } from '../common/Request'

@ComponentV2
export default struct Login {
  @Consumer() isShowLoginSheet: boolean = false
  @Local type: string = 'password'
  @Local email: string = ''
  @Local password: string = ''
  @Local mfa: string = ''
  @Local emailcode: string = ''
  @Local agree: boolean = false
  @Local buttonText: string = '获取验证码'
  @Local buttonEnabled: boolean = true
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton(async (err, response) => {
        if (response) {
          this.dialogControllerProgress.open()
          netBoost.setSceneDesc({
            scene: 'login',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
          })
          const res = await developerRequest(this.context, '/account/getAccessToken', {
            verifyType: 'huaweiaitodoapp',
            verifyCode: response.authorizationCode
          })
          netBoost.setSceneDesc({
            scene: 'login',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
          })
          this.dialogControllerProgress.close()
          if (res !== 'fail') {
            const accessToken = JSON.parse(res).accessToken as string
            const uid = JSON.parse(res).uid as string
            const email = JSON.parse(res).email as string
            const endDate = JSON.parse(res).endDate as number
            await setPersonalAccount(accessToken, {
              uid: uid,
              email: email,
              endDate: endDate
            })
            await promptAction.openToast({
              message: '登录成功'
            })
            this.isShowLoginSheet = false
          }
        }
        if (err) {
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
          })
        }
      })

  build() {
    List() {
      ListItem() {
        Column() {
          Row() {
            Text('方式')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Flex({
              wrap: FlexWrap.Wrap,
              space: {
                main: LengthMetrics.vp(8),
                cross: LengthMetrics.vp(8)
              }
            }) {
              Row() {
                Radio({
                  value: 'password',
                  group: 'type'
                })
                  .checked(this.type === 'password' ? true : false)
                  .onChange(isChecked => {
                    if (isChecked) {
                      this.type = 'password'
                    }
                  })
                Text('密码')
              }

              Row() {
                Radio({
                  value: 'mfa',
                  group: 'type'
                })
                  .checked(this.type === 'mfa' ? true : false)
                  .onChange(isChecked => {
                    if (isChecked) {
                      this.type = 'mfa'
                    }
                  })
                Text('MFA')
              }

              Row() {
                Radio({
                  value: 'emailcode',
                  group: 'type'
                })
                  .checked(this.type === 'emailcode' ? true : false)
                  .onChange(isChecked => {
                    if (isChecked) {
                      this.type = 'emailcode'
                    }
                  })
                Text('邮箱验证码')
              }
            }
            .layoutWeight(1)
          }

          Row() {
            Text('邮箱')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入邮箱',
              text: this.email!!
            })
              .contentType(ContentType.EMAIL_ADDRESS)
              .enableAutoSpacing(true)
              .layoutWeight(1)
              .type(InputType.Email)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          if (this.type === 'password') {
            Row() {
              Text('密码')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入密码',
                text: this.password!!
              })
                .contentType(ContentType.PASSWORD)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .maxLength(32)
                .type(InputType.Password)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
          if (this.type === 'mfa') {
            Row() {
              Text('MFA')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入MFA',
                text: this.mfa!!
              })
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .maxLength(6)
                .type(InputType.Number)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
          if (this.type === 'emailcode') {
            Row() {
              Text('验证码')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入邮箱验证码',
                text: this.emailcode!!
              })
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .maxLength(8)
                .type(InputType.Number)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Button(this.buttonText)
              .buttonStyle(ButtonStyleMode.NORMAL)
              .enabled(this.buttonEnabled)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(async () => {
                if (!this.email) {
                  await promptAction.openToast({
                    message: '请输入邮箱'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const res = await developerRequest(this.context, '/account/sendEmailCode', {
                  email: this.email
                })
                this.dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.openToast({
                    message: '验证码已成功发送到邮箱：' + this.email
                  })
                  this.buttonEnabled = false
                  let countdown = 60
                  const interval = setInterval(() => {
                    countdown--
                    if (countdown > 0) {
                      this.buttonText = '重新发送 (' + countdown + ')'
                    } else {
                      clearInterval(interval)
                      this.buttonEnabled = true
                      this.buttonText = '获取验证码'
                    }
                  }, 1000)
                }
              })
          }
          Button('登录')
            .enabled(this.agree)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .width('100%')
            .onClick(async () => {
              if (!this.email) {
                await promptAction.openToast({
                  message: '请输入邮箱'
                })
                return
              }
              if (this.type === 'password' && this.password.length < 8) {
                await promptAction.openToast({
                  message: '请输入正确的密码'
                })
                return
              }
              if (this.type === 'mfa' && this.mfa.length !== 6) {
                await promptAction.openToast({
                  message: '请输入正确的 MFA'
                })
                return
              }
              if (this.type === 'emailcode' && this.emailcode.length !== 8) {
                await promptAction.openToast({
                  message: '请输入正确的邮箱验证码'
                })
                return
              }
              let code = ''
              if (this.type === 'password') {
                code = this.password
              }
              if (this.type === 'mfa') {
                code = this.mfa
              }
              if (this.type === 'emailcode') {
                code = this.emailcode
              }
              this.dialogControllerProgress.open()
              netBoost.setSceneDesc({
                scene: 'login',
                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
              })
              const res = await developerRequest(this.context, '/account/getAccessToken', {
                verifyType: this.type,
                verifyCode: code,
                email: this.email
              })
              netBoost.setSceneDesc({
                scene: 'login',
                sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
              })
              this.dialogControllerProgress.close()
              if (res !== 'fail') {
                const accessToken = JSON.parse(res).accessToken as string
                const uid = JSON.parse(res).uid as string
                const email = JSON.parse(res).email as string
                const endDate = JSON.parse(res).endDate as number
                await setPersonalAccount(accessToken, {
                  uid: uid,
                  email: email,
                  endDate: endDate
                })
                await promptAction.openToast({
                  message: '登录成功'
                })
                this.isShowLoginSheet = false
              }
            })
          LoginWithHuaweiIDButton({
            params: {
              style: loginComponentManager.Style.BUTTON_RED,
              extraStyle: {
                buttonStyle: new loginComponentManager.ButtonStyle().loadingStyle({
                  show: true
                })
              }
            },
            controller: this.controller
          })
            .height(40)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          Button('通行密钥登录')
            .enabled(this.agree)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .width('100%')
            .onClick(async () => {
              try {
                const publicKeyAssertionCredential = await fido2.authenticate(this.context, {
                  publicKey: {
                    challenge: new util.TextEncoder().encodeInto(String(Date.now()).slice(0, -5) + '00000'),
                    timeout: 100000,
                    rpId: 'www.zhangls2512.cn'
                  }
                })
                this.dialogControllerProgress.open()
                netBoost.setSceneDesc({
                  scene: 'login',
                  sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
                })
                const loginResponse = await developerRequest(this.context, '/account/getAccessToken', {
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
                this.dialogControllerProgress.close()
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
                    message: '登录成功'
                  })
                  this.isShowLoginSheet = false
                }
              } catch (err) {
                if (err.code !== 1021300004) {
                  await promptAction.openToast({
                    message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                  })
                }
              }
            })
          Text('注册账号')
            .fontColor($r('sys.color.font_emphasize'))
            .fontWeight(FontWeight.Medium)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .onClick(async () => {
              await openLink(this.context, 'https://www.zhangls2512.cn/product/account/register')
            })
          Row() {
            Toggle({
              type: ToggleType.Checkbox,
              isOn: this.agree!!
            })
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .onChange(isOn => {
                this.controller.setEnabled(isOn)
              })
            Text() {
              Span('已阅读并同意')
              Span('《轩铭智能待办用户服务条款与条件》')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(async () => {
                  try {
                    const appPrivacyLink = privacyManager.getAppPrivacyMgmtInfo().privacyInfo
                      .find(item => item.type === privacyManager.AppPrivacyLinkType.USER_AGREEMENT_LINK)
                    await openLink(this.context, appPrivacyLink?.url as string)
                  } catch (err) {
                    await promptAction.openToast({
                      message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                    })
                  }
                })
              Span('《关于轩铭智能待办与隐私的声明》')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(async () => {
                  try {
                    const appPrivacyLink = privacyManager.getAppPrivacyMgmtInfo().privacyInfo
                      .find(item => item.type === privacyManager.AppPrivacyLinkType.PRIVACY_STATEMENT_LINK)
                    await openLink(this.context, appPrivacyLink?.url as string)
                  } catch (err) {
                    await promptAction.openToast({
                      message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
                    })
                  }
                })
              Span('。如果使用华为账号登录，已阅读并同意')
              Span('《华为账号用户认证协议》')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(async () => {
                  await openLink(this.context,
                    'https://privacy.consumer.huawei.com/legal/id/authentication-terms.htm?code=CN&language=zh-CN')
                })
              Span('《关于华为账号与隐私的声明》')
                .fontColor($r('sys.color.font_emphasize'))
                .onClick(async () => {
                  await openLink(this.context,
                    'https://legal.cloud.huawei.com/terms/scope/huawei/id-hmos/privacy-statement.htm?code=CN&language=zh-CN')
                })
              Span('。')
            }
            .fontSize($r('sys.float.ohos_id_text_size_body3'))
            .layoutWeight(1)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_l')
          })
        }
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(() => {
      this.controller.setEnabled(false)
    })
  }
}