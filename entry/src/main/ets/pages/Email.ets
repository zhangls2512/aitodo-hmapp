import { common } from '@kit.AbilityKit'
import { loginComponentManager, LoginWithHuaweiIDButton } from '@kit.AccountKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import {
  getPersonalAccountAccessToken,
  getPersonalAccountInfo,
  removeAccount,
  setPersonalAccount
} from '../common/Account'
import { developerRequest } from '../common/Request'

@Builder
export function EmailBuilder() {
  Email()
}

@ComponentV2
struct Email {
  @Local email: string = ''
  @Local emailcode: string = ''
  @Local buttonText: string = '获取验证码'
  @Local buttonEnabled: boolean = true
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })
  controller: loginComponentManager.LoginWithHuaweiIDButtonController =
    new loginComponentManager.LoginWithHuaweiIDButtonController()
      .onClickLoginWithHuaweiIDButton(async (err, response) => {
        if (!this.email) {
          await promptAction.openToast({
            message: '请输入邮箱'
          })
          return
        }
        if (this.emailcode.length !== 8) {
          await promptAction.openToast({
            message: '请输入正确的邮箱验证码'
          })
          return
        }
        if (response) {
          this.dialogControllerProgress.open()
          const res = await developerRequest(this.context, '/account/updateEmail', {
            verifyType: 'huaweiaitodoapp',
            verifyCode: response.authorizationCode,
            newEmail: this.email,
            newEmailCode: this.emailcode
          })
          this.dialogControllerProgress.close()
          if (res !== 'fail') {
            await promptAction.openToast({
              message: '绑定成功'
            })
            const accessToken = await getPersonalAccountAccessToken()
            const accountInfo = await getPersonalAccountInfo()
            await removeAccount('personal')
            await setPersonalAccount(accessToken, {
              uid: accountInfo.uid,
              email: this.email,
              endDate: accountInfo.endDate
            })
            this.pageInfos.pop()
            this.context.eventHub.emit('refreshSetting')
            this.context.eventHub.emit('refreshMe')
          }
        }
        if (err) {
          await promptAction.openToast({
            message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
          })
        }
      })

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Column() {
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
                .defaultFocus(true)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .type(InputType.Email)
            }

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
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
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
          mainTitle: '绑定邮箱'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
    })
  }
}