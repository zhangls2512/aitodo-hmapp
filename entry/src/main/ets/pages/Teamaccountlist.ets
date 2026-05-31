import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import copy from '../common/Pasteboard'
import { teamRequest } from '../common/Request'
import { Param } from './Updateteamaccount'

interface TeamAccountItem {
  userId: string,
  userName: string,
  userEnabled: boolean,
  permission: string[]
}

@Builder
export function TeamaccountlistBuilder() {
  Teamaccountlist()
}

@ComponentV2
struct Teamaccountlist {
  @Local teamAccountArray: TeamAccountItem[] = []
  @Local hoverId: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  teamId = ''
  empty: boolean | undefined = undefined
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })
  permissionMap: Record<string, string> = {
    'newTodo': '新增待办',
    'getTodo': '查看待办'
  }

  async get() {
    this.teamAccountArray = []
    this.dialogControllerProgress.open()
    const res = await teamRequest(this.context, this.teamId, '/getUserList', {
      skip: this.teamAccountArray.length
    })
    this.dialogControllerProgress.close()
    if (res !== 'fail') {
      this.teamAccountArray = JSON.parse(res).data
    }
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Button('新增')
            .width('100%')
            .onClick(() => {
              this.pageInfos.pushPath({
                name: 'Newteamaccount',
                param: this.teamId
              })
            })
        }
        .margin({
          bottom: $r('sys.float.ohos_id_elements_margin_vertical_m'),
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        if (this.teamAccountArray.length === 0) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ForEach(this.teamAccountArray, (item: TeamAccountItem, index) => {
          ListItem() {
            Column() {
              Row() {
                Text('ID')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.userId)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === '0,' + index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = ''
                }
                if (isHover) {
                  this.hoverId = '0,' + index
                }
              })
              .onClick(async () => {
                await copy(this.context, this.UIContext, item.userId)
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('名')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.userName)
                  .enableAutoSpacing(true)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('权限')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.permission.map(item => this.permissionMap[item]).join('、') ?
                  item.permission.map(item => this.permissionMap[item]).join('、') : '无')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text(item.userEnabled ? '禁用' : '启用')
                  .fontColor(item.userEnabled ? $r('sys.color.warning') : $r('sys.color.font_emphasize'))
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === '1,' + index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = ''
                }
                if (isHover) {
                  this.hoverId = '1,' + index
                }
              })
              .onClick(async () => {
                this.dialogControllerProgress.open()
                const res = await teamRequest(this.context, this.teamId, '/updateUserEnabled', {
                  id: item.userId
                })
                this.dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.openToast({
                    message: (item.userEnabled ? '禁用' : '启用') + '成功'
                  })
                  await this.get()
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('重置密码')
                  .fontColor($r('sys.color.warning'))
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === '2,' + index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = ''
                }
                if (isHover) {
                  this.hoverId = '2,' + index
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '重置密码为 ID，确定重置？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '确定',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  this.dialogControllerProgress.open()
                  const res = await teamRequest(this.context, this.teamId, '/resetUserPassword', {
                    id: item.userId
                  })
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '重置成功'
                    })
                  }
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('修改')
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === '3,' + index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = ''
                }
                if (isHover) {
                  this.hoverId = '3,' + index
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Updateteamaccount',
                  param: {
                    teamId: this.teamId,
                    userId: item.userId,
                    name: item.userName,
                    permission: item.permission
                  } as Param
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('删除')
                  .fontColor($r('sys.color.warning'))
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Image($r('app.media.right'))
                  .fillColor($r('sys.color.icon_fourth'))
                  .height(12)
                  .width(12)
              }
              .borderRadius(12)
              .padding(12)
              .stateStyles({
                normal: {
                  .backgroundColor(this.hoverId === '4,' + index ? $r('sys.color.interactive_hover') :
                    $r('sys.color.ohos_id_color_card_bg'))
                },
                pressed: {
                  .backgroundColor($r('sys.color.interactive_pressed'))
                }
              })
              .onHover(isHover => {
                if (!isHover) {
                  this.hoverId = ''
                }
                if (isHover) {
                  this.hoverId = '4,' + index
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '删除成功后无法恢复，确定删除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '确定',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  this.dialogControllerProgress.open()
                  const res = await teamRequest(this.context, this.teamId, '/deleteUser', {
                    id: item.userId
                  })
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                    await this.get()
                  }
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
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
      .onReachEnd(async () => {
        if (this.empty === false && this.teamAccountArray.length > 0) {
          this.dialogControllerProgress.open()
          const res = await teamRequest(this.context, this.teamId, '/getUserList', {
            skip: this.teamAccountArray.length
          })
          this.dialogControllerProgress.close()
          if (res !== 'fail') {
            const array = JSON.parse(res).data as TeamAccountItem[]
            if (array.length === 0) {
              this.empty = true
            }
            this.teamAccountArray = this.teamAccountArray.concat(array)
          }
        }
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
          mainTitle: '用户管理'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.teamId = context.pathInfo.param as string
      this.context.eventHub.on('refreshTeamaccountlist', async () => {
        await this.get()
      })
      await this.get()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshTeamaccountlist')
    })
  }
}