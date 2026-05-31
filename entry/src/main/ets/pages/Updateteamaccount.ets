import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { teamRequest } from '../common/Request'

export interface Param {
  teamId: string,
  userId: string,
  name: string,
  permission: string[]
}

@Builder
export function UpdateteamaccountBuilder() {
  Updateteamaccount()
}

@ComponentV2
struct Updateteamaccount {
  @Local name: string = ''
  @Local permission: string[] = []
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  teamId = ''
  userId = ''

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
              Text('名')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入名',
                text: this.name!!
              })
                .enableAutoSpacing(true)
                .layoutWeight(1)
            }

            Column() {
              Text('权限')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  bottom: 6,
                  left: 12,
                  right: 12
                })
              Column() {
                Row() {
                  Text('新增待办')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.permission.includes('newTodo')
                  })
                    .onChange(isOn => {
                      if (!isOn) {
                        this.permission = this.permission.filter(inItem => inItem !== 'newTodo')
                      }
                      if (isOn) {
                        this.permission = Array.from(new Set([...this.permission, 'newTodo']))
                      }
                    })
                }
                .borderRadius(12)
                .padding(12)

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Column() {
                    Text('查看待办')
                      .fontWeight(FontWeight.Medium)
                    Text('授予此权限可查看团队所有待办。待办新增、执行、查看、审核者默认拥有待办级查看权限，无需授予此权限')
                      .fontColor($r('sys.color.font_secondary'))
                      .fontSize($r('sys.float.ohos_id_text_size_body2'))
                      .margin({
                        top: $r('sys.float.ohos_id_text_margin_vertical')
                      })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })

                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.permission.includes('getTodo')
                  })
                    .onChange(isOn => {
                      if (!isOn) {
                        this.permission = this.permission.filter(inItem => inItem !== 'getTodo')
                      }
                      if (isOn) {
                        this.permission = Array.from(new Set([...this.permission, 'getTodo']))
                      }
                    })
                }
                .borderRadius(12)
                .padding(12)
              }
              .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .padding($r('sys.float.ohos_id_corner_radius_mark'))
            }
            .alignItems(HorizontalAlign.Start)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Button('修改')
              .keyboardShortcut('S', [ModifierKey.CTRL])
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .width('100%')
              .onClick(async () => {
                if (!this.name) {
                  await promptAction.openToast({
                    message: '请输入名'
                  })
                  return
                }
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '请求中...'
                  })
                })
                dialogControllerProgress.open()
                const res = await teamRequest(this.context, this.teamId, '/updateUserInfo', {
                  id: this.userId,
                  name: this.name,
                  permission: this.permission
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.openToast({
                    message: '修改成功'
                  })
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshTeamaccountlist')
                }
              })
          }
          .alignItems(HorizontalAlign.Start)
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
          mainTitle: '修改用户'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
      const param = context.pathInfo.param as Param
      this.teamId = param.teamId
      this.userId = param.userId
      this.name = param.name
      this.permission = param.permission
    })
  }
}