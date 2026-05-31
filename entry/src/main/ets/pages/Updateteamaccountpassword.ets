import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getTeamAccountInfo, removeAccount } from '../common/Account'
import { teamRequest } from '../common/Request'

@Builder
export function UpdateteamaccountpasswordBuilder() {
  Updateteamaccountpassword()
}

@ComponentV2
struct Updateteamaccountpassword {
  @Local password: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  teamId = ''

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
              Text('新密码')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入新密码',
                text: this.password!!
              })
                .contentType(ContentType.PASSWORD)
                .defaultFocus(true)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .maxLength(32)
                .type(InputType.Password)
            }

            Button('修改')
              .keyboardShortcut('S', [ModifierKey.CTRL])
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .width('100%')
              .onClick(async () => {
                if (this.password.length < 8) {
                  await promptAction.openToast({
                    message: '密码长度过短'
                  })
                  return
                }
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '请求中...'
                  })
                })
                dialogControllerProgress.open()
                const res = await teamRequest(this.context, this.teamId, '/updateUserPassword', {
                  password: this.password
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  const teamAccountInfo = await getTeamAccountInfo(this.teamId)
                  await removeAccount(teamAccountInfo.id)
                  await promptAction.openToast({
                    message: '修改成功，请重新登录'
                  })
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshTeam')
                }
              })
          }
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

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
          mainTitle: '修改密码'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
      this.teamId = context.pathInfo.param as string
    })
  }
}