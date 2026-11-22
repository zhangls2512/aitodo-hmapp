import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { fido2 } from '@kit.OnlineAuthenticationKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getPersonalAccountInfo } from '../common/Account'
import { developerRequest } from '../common/Request'

@Builder
export function NewpasskeyBuilder() {
  Newpasskey()
}

@ComponentV2
struct Newpasskey {
  @Local email: string = ''
  @Local mfa: string = ''
  @Local emailcode: string = ''
  @Local buttonEnabled: boolean = true
  @Local type: string = 'mfa'
  @Local buttonText: string = '获取验证码'
  @Local attestationObject: string = ''
  @Local clientDataJSON: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        if (this.email && this.attestationObject && this.clientDataJSON) {
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
              Button('新增')
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
                .width('100%')
                .onClick(async () => {
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
                  if (this.type === 'mfa') {
                    code = this.mfa
                  }
                  if (this.type === 'emailcode') {
                    code = this.emailcode
                  }
                  this.dialogControllerProgress.open()
                  const res = await developerRequest(this.context, '/account/bindExternalAccount', {
                    email: this.email,
                    verifyType: this.type,
                    verifyCode: code,
                    platform: 'passkey',
                    attestationObject: this.attestationObject,
                    clientDataJSON: this.clientDataJSON
                  })
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '新增成功'
                    })
                    this.pageInfos.pop()
                  }
                })
            }
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ListItem()
          .margin({
            bottom: 28
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .recoverable(true)
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary')
            },
            backIconStyle: {
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '新增通行密钥'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      const accountInfo = await getPersonalAccountInfo()
      this.email = accountInfo.email
      if (this.email) {
        try {
          const res = await fido2.register(this.context, {
            publicKey: {
              rp: {
                id: 'zhangls2512.cn',
                name: 'zhangls2512.cn'
              },
              user: {
                id: new util.TextEncoder().encodeInto(accountInfo.uid),
                name: accountInfo.email,
                displayName: accountInfo.email
              },
              challenge: new util.TextEncoder().encodeInto(String(Date.now()).slice(0, -5) + '00000'),
              pubKeyCredParams: [
                {
                  type: fido2.PublicKeyCredentialType.PUBLIC_KEY,
                  alg: fido2.Algorithm.ES256
                }
              ],
              authenticatorSelection: {
                residentKey: fido2.UserVerificationRequirement.PREFERRED
              }
            }
          })
          this.attestationObject =
            new util.Base64Helper().encodeToStringSync(res.response.attestationObject, util.Type.BASIC_URL_SAFE)
          this.clientDataJSON =
            new util.Base64Helper().encodeToStringSync(res.response.clientDataJson, util.Type.BASIC_URL_SAFE)
        } catch (err) {
          if (err.code !== 1021300004) {
            await promptAction.openToast({
              message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
            })
          }
          if (err.code === 1021300004) {
            this.pageInfos.pop()
          }
        }
      }
    })
  }
}